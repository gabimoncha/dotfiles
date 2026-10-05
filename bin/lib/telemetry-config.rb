#!/usr/bin/ruby
# Preserve unrelated settings; validate before an atomic, backed-up write.
require 'json'
require 'fileutils'
require 'tempfile'

def update_file(path)
  path = File.realpath(path) if File.symlink?(path)
  before = File.exist?(path) ? File.binread(path) : nil
  after = yield((before || '').dup)
  return if before == after
  FileUtils.mkdir_p(File.dirname(path))
  if before
    backup = File.join(ENV.fetch('HOME'), '.dotfiles-backups',
                       Time.now.strftime('%Y%m%d-%H%M%S-%N'), 'telemetry',
                       path.sub(%r{\A/}, ''))
    FileUtils.mkdir_p(File.dirname(backup))
    File.write(backup, before, mode: 'wb', perm: 0600)
  end
  Tempfile.create(['.telemetry-', '.tmp'], File.dirname(path)) do |file|
    file.chmod(before ? File.stat(path).mode & 0777 : 0600)
    file.write(after)
    file.flush
    file.fsync
    file.close
    File.rename(file.path, path)
  end
end

def merge_json(path, desired)
  update_file(path) do |text|
    current = text.empty? ? {} : JSON.parse(text)
    raise 'Settings must be a JSON object' unless current.is_a?(Hash)
    merge = lambda do |target, source|
      source.each do |key, value|
        if value.is_a?(Hash)
          raise "#{key} must be a JSON object" if target.key?(key) && !target[key].is_a?(Hash)
          target[key] ||= {}
          merge.call(target[key], value)
        else
          target[key] = value
        end
      end
    end
    before = JSON.generate(current)
    merge.call(current, desired)
    before == JSON.generate(current) && !text.empty? ? text : JSON.pretty_generate(current) + "\n"
  end
end

def jsonc_tokens(text)
  tokens = []
  i = 0
  depth = 0
  while i < text.length
    if text[i].match?(/\s/)
      i += 1
    elsif text[i, 2] == '//'
      i = text.index("\n", i) || text.length
    elsif text[i, 2] == '/*'
      ending = text.index('*/', i + 2)
      raise 'Unterminated JSONC comment' unless ending
      i = ending + 2
    else
      start = i
      if text[i] == '"'
        i += 1
        while i < text.length && text[i] != '"'
          i += text[i] == '\\' ? 2 : 1
        end
        raise 'Unterminated JSONC string' if i >= text.length
        i += 1
      elsif '{}[]:,'.include?(text[i])
        i += 1
      else
        i += 1 while i < text.length && !text[i].match?(/[\s{}\[\]:,\/]/)
        raise 'Invalid JSONC token' if start == i
      end
      literal = text[start...i]
      tokens << {literal: literal, start: start, finish: i, depth: depth}
      depth += 1 if ['{', '['].include?(literal)
      depth -= 1 if ['}', ']'].include?(literal)
    end
  end
  clean = tokens.each_with_index.reject do |token, index|
    token[:literal] == ',' && tokens[index + 1] && ['}', ']'].include?(tokens[index + 1][:literal])
  end.map { |token, _| token[:literal] }.join(' ')
  [tokens, JSON.parse(clean)]
end

def merge_jsonc(path, desired)
  update_file(path) do |text|
    text = "{}\n" if text.empty?
    tokens, current = jsonc_tokens(text)
    raise 'Settings must be a JSONC object' unless current.is_a?(Hash)
    changes = []
    found = []
    tokens.each_with_index do |token, index|
      next unless token[:depth] == 1 && token[:literal].start_with?('"') && tokens[index + 1][:literal] == ':'
      key = JSON.parse(token[:literal])
      next unless desired.key?(key)
      found << key
      first = index + 2
      last = first
      last += 1 while tokens[last] && !(tokens[last][:depth] == 1 && [',', '}'].include?(tokens[last][:literal]))
      changes << [tokens[first][:start], tokens[last - 1][:finish], JSON.generate(desired[key])]
    end
    missing = desired.keys - found
    unless missing.empty?
      comma = current.empty? || tokens[-2][:literal] == ',' ? '' : ','
      insertion = comma + "\n" + missing.map { |key| "  #{JSON.generate(key)}: #{JSON.generate(desired[key])}" }.join(",\n") + "\n"
      changes << [tokens.last[:start], tokens.last[:start], insertion]
    end
    changes.sort_by { |start, _, _| -start }.each { |start, finish, value| text[start...finish] = value }
    # Validate the result before creating a backup or replacing the file.
    _, updated = jsonc_tokens(text)
    raise 'JSONC merge verification failed' unless desired.all? { |key, value| updated[key] == value }
    text
  end
end

def toml_line_code(line, multiline)
  code = ''
  quote = nil
  i = 0
  while i < line.length
    if multiline
      if multiline == '"""' && line[i] == '\\'
        i += 2
      elsif line[i, 3] == multiline
        multiline = nil
        i += 3
      else
        i += 1
      end
    elsif quote
      code << line[i]
      if quote == '"' && line[i] == '\\'
        i += 1
        code << line[i] if i < line.length
      elsif line[i] == quote
        quote = nil
      end
      i += 1
    elsif line[i] == '#'
      break
    elsif ['"', "'"].include?(line[i])
      if ['"""', "'''"].include?(line[i, 3])
        multiline = line[i, 3]
        code << multiline
        i += 3
      else
        quote = line[i]
        code << line[i]
        i += 1
      end
    else
      code << line[i]
      i += 1
    end
  end
  raise 'Unterminated TOML string; existing settings were preserved.' if quote
  [code.strip, multiline]
end

def toml_value_depth(code)
  depth = 0
  quote = nil
  i = 0
  while i < code.length
    character = code[i]
    if quote
      if quote == '"' && character == '\\'
        i += 1
      elsif character == quote
        quote = nil
      end
    elsif ['"""', "'''"].include?(code[i, 3])
      # toml_line_code emits this marker and removes multiline contents.
      i += 2
    elsif ['"', "'"].include?(character)
      quote = character
    elsif ['[', '{'].include?(character)
      depth += 1
    elsif [']', '}'].include?(character)
      depth -= 1
    end
    i += 1
  end
  depth
end

def merge_codex(path)
  # This is a surgical merger, not a complete TOML parser.
  # Only change simple scalar keys in standard TOML tables. Reject ambiguous
  # representations before any write, rather than duplicate a TOML table/key.
  desired = {'analytics' => {'enabled' => 'false'},
             'otel' => {'exporter' => '"none"', 'metrics_exporter' => '"none"',
                        'trace_exporter' => '"none"', 'log_user_prompt' => 'false'}}
  update_file(path) do |text|
    lines = text.lines
    section = nil
    tables = {}
    matches = {}
    multiline = nil
    value_depth = 0
    lines.each_with_index do |line, index|
      continued_string = !multiline.nil?
      code, multiline = toml_line_code(line, multiline)
      if continued_string || value_depth > 0
        value_depth += toml_value_depth(code)
        raise 'Unbalanced TOML value; existing settings were preserved.' if value_depth < 0
        next
      end
      if code.start_with?('[')
        # Escaped quoted names can resolve to a managed table. Do not append
        # an equivalent table without a complete TOML name decoder.
        if code.match?(/"[^"\n]*\\/)
          raise 'Escaped TOML table names need manual telemetry configuration.'
        end
        section = code[/\A\[\s*(?:"|')?(analytics|otel)(?:"|')?\s*\]\s*(?:#.*)?\z/, 1]
        if section
          raise "Duplicate #{section} table" if tables.key?(section)
          tables[section] = index
        end
        # An exporter encoded as a nested table cannot safely become a scalar.
        if code.match?(/\A\[+\s*(?:"|')?(analytics|otel)(?:"|')?\s*\./) || code.match?(/\A\[\[\s*(?:"|')?(analytics|otel)(?:"|')?\s*\]/)
          raise 'Codex has nested or array telemetry tables. Use standard [analytics] and [otel] scalar settings, then retry.'
        end
        next
      end
      if code.split('=', 2).first.to_s.match?(/"[^"\n]*\\/)
        raise 'Escaped TOML key names need manual telemetry configuration.'
      end
      if section && (key = code[/\A(?:"|')?([A-Za-z_]+)(?:"|')?\s*=/, 1]) && desired[section].key?(key)
        raise "Duplicate #{section}.#{key}" if matches.key?([section, key])
        # Do not delete an inline exporter object or a multiline value.
        unless code.match?(/\A(?:"|')?#{key}(?:"|')?\s*=\s*(?:true|false|"[^"\n]*"|'[^'\n]*')\s*(?:#.*)?\z/)
          raise "Complex #{section}.#{key}; set this key manually, then retry."
        end
        matches[[section, key]] = index
      elsif section && (key = code[/\A(?:"|')?([A-Za-z_]+)(?:"|')?\s*\./, 1]) && desired[section].key?(key)
        # A dotted key makes the managed key a table; a scalar would duplicate it.
        raise "Codex #{section}.#{key} uses dotted keys. Set this key manually, then retry."
      elsif code.match?(/\A(?:"|')?(analytics|otel)(?:"|')?\s*(?:\.|=)/)
        raise 'Codex telemetry uses dotted keys or inline tables. Use standard [analytics] and [otel] tables, then retry.'
      end
      value_depth += toml_value_depth(code)
      raise 'Unbalanced TOML value; existing settings were preserved.' if value_depth < 0
    end
    raise 'Unterminated TOML multiline string' if multiline
    raise 'Unterminated TOML value; existing settings were preserved.' unless value_depth == 0
    desired.each do |table, keys|
      if tables.key?(table)
        pending = []
        keys.each do |key, value|
          index = matches[[table, key]]
          if index
            # Preserve the key spelling, indentation, and trailing comment.
            lines[index] = lines[index].sub(/(=\s*)(?:true|false|"[^"\n]*"|'[^'\n]*')/) { $1 + value }
          else
            pending << "#{key} = #{value}\n"
          end
        end
        unless pending.empty?
          lines[tables[table]] += "\n" unless lines[tables[table]].end_with?("\n")
          lines[tables[table]] += pending.join
        end
      else
        lines << "\n" unless lines.empty? || lines.last.end_with?("\n")
        lines << "\n[#{table}]\n"
        keys.each { |key, value| lines << "#{key} = #{value}\n" }
      end
    end
    lines.join
  end
end

begin
  kind, path, source = ARGV
  case kind
  when 'codex' then merge_codex(path)
  when 'json' then merge_json(path, JSON.parse(File.read(source)))
  when 'jsonc' then merge_jsonc(path, JSON.parse(File.read(source)))
  else abort 'Unknown telemetry configuration format'
  end
rescue StandardError => error
  # A parser error can contain personal configuration contents. Never log it.
  warn(error.is_a?(JSON::ParserError) ? 'Invalid JSON/JSONC; existing settings were preserved.' : error.message)
  exit 1
end
