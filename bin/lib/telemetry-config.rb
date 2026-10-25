#!/usr/bin/ruby
# Set telemetry keys in a JSON file with comments (JSONC), such as Cursor's
# settings. mise cannot merge into a file with comments. Preserve unrelated
# settings; validate before an atomic, backed-up write.
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

begin
  kind, path, source = ARGV
  abort "Usage: telemetry-config.rb jsonc TARGET SOURCE" unless kind == "jsonc" && path && source
  merge_jsonc(path, JSON.parse(File.read(source)))
rescue StandardError => error
  # A parser error can contain personal configuration contents. Never log it.
  warn(error.is_a?(JSON::ParserError) ? "Invalid JSON/JSONC; existing settings were preserved." : error.message)
  exit 1
end
