#!/usr/bin/ruby
# Selects the public settings of one live settings file for bin/save-settings.
#
# Usage: settings-sync.rb SOURCE SOURCE_JSON LIVE_JSON OUTPUT_JSON [--show-new]
#
# SOURCE is the repository file, such as configs/claude/settings.json.
# SOURCE_JSON and LIVE_JSON hold it and the live file as JSON. The sync-keys
# file next to SOURCE has one rule per line: "public PATH" or "private PATH",
# where PATH is a key path such as .model or .env."NAME". A public rule names
# one setting: a string, a number, a boolean, or a list of those. A private
# rule can name a whole section. Settings under no rule are counted, not
# saved; --show-new prints their paths. Each setting in SOURCE needs a public
# rule, so that a save cannot delete it. Saved values must not hold a local
# path, a credential, or an email address. Messages print only paths from
# sync-keys and SOURCE.
require 'json'

PATH_SYNTAX = /\A(?:\.[A-Za-z0-9_-]+|\."[^"]+")+\z/
PRIVATE_TEXT = Regexp.union(
  # An absolute or home path after the start, a space, a quote, or a
  # separator. A URL path follows "//host", so it does not match.
  %r#(?:\A|[\s"'=(,;:\[{])(?:/(?!/)|~[A-Za-z0-9_.-]*/|\$\{?HOME\b|[A-Za-z]:[\\/]|\\\\)#,
  /\A~\z/,
  /\bfile:/i,
  %r{://[^/@\s]+:[^/@\s]*@},
  /\b(?:Bearer|Basic)\s+\S/i,
  /\b(?:sk|pk|rk)-[A-Za-z0-9_-]{8,}/,
  /\bgh[pousr]_[A-Za-z0-9]{12,}/,
  /\bgithub_pat_/,
  /\bxox[abprs]-/,
  /\bAKIA[0-9A-Z]{12,}/,
  /-----BEGIN/,
  /\beyJ[A-Za-z0-9_-]{8,}\./,
  /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/,
  /[\r\n]/
)
SECRET_NAME = /(?:\A|[_.-])(?:api_?key|secret|password|passwd|passphrase|private_?key|credentials?|(?:auth|access|refresh|bearer|session)_?token|token|headers?)\z|\A(?:authorization|cookie)\z/i

def fail!(message)
  warn "save-settings: #{message}"
  exit 1
end

def parse_path(text, file, number)
  fail!("#{file}:#{number} is not a key path") unless text.match?(PATH_SYNTAX)
  text.scan(/\.(?:"([^"]+)"|([A-Za-z0-9_-]+))/).map { |quoted, plain| quoted || plain }
end

def show(keys)
  keys.map { |key| key.to_s.match?(/\A[A-Za-z0-9_-]+\z/) ? ".#{key}" : ".\"#{key}\"" }.join
end

def prefix?(short, long)
  long.length >= short.length && long[0, short.length] == short
end

def lookup(data, keys)
  keys.each do |key|
    return [false, nil] unless data.is_a?(Hash) && data.key?(key)
    data = data[key]
  end
  [true, data]
end

def store(data, keys, value)
  node = keys[0...-1].reduce(data) { |current, key| current[key] = {} unless current[key].is_a?(Hash); current[key] }
  node[keys.last] = value
end

# Yields the path of every leaf: a value that is not a map, or an empty map.
def leaves(node, keys = [], &block)
  if node.is_a?(Hash) && !node.empty?
    node.each { |key, value| leaves(value, keys + [key], &block) }
  else
    yield keys
  end
end

def read_map(file, name)
  data = begin
    JSON.parse(File.read(file))
  rescue JSON::ParserError
    fail!("#{name} is not valid. Nothing saved")
  end
  fail!("#{name} does not hold one map. Nothing saved") unless data.is_a?(Hash)
  data
end

source_file, source_json, live_file, output_file, option = ARGV
fail!('usage: settings-sync.rb SOURCE SOURCE_JSON LIVE_JSON OUTPUT_JSON [--show-new]') unless output_file
sync_file = File.join(File.dirname(source_file), 'sync-keys')
public_rules = []
private_rules = []
File.readlines(sync_file).each_with_index do |line, index|
  line = line.strip
  next if line.empty? || line.start_with?('#')
  kind, text = line.split(/\s+/, 2)
  fail!("#{sync_file}:#{index + 1} must start with public or private") unless %w[public private].include?(kind) && text
  (kind == 'public' ? public_rules : private_rules) << parse_path(text, sync_file, index + 1)
end

saved = read_map(source_json, source_file)
live = read_map(live_file, 'the live settings file')

problems = []
leaves(saved) do |keys|
  next if keys.empty?
  next if public_rules.include?(keys) && private_rules.none? { |rule| prefix?(rule, keys) }
  problems << "#{show(keys)} is in #{source_file} but not public in #{sync_file}, so a save would delete it. Make it public, or delete it from #{source_file}"
end

output = {}
public_rules.each do |keys|
  next if private_rules.any? { |rule| prefix?(rule, keys) }
  found, value = lookup(live, keys)
  next unless found
  case value
  when Hash
    # A section can gain new fields, such as exporter headers.
    problems << "#{show(keys)} is now a section, not one setting. Give its settings their own rules in #{sync_file}, or mark it private"
    next
  when Array
    unless value.all? { |item| item.is_a?(String) || item.is_a?(Numeric) || item == true || item == false }
      problems << "#{show(keys)} is a list of sections. Mark it private in #{sync_file}"
      next
    end
  end
  texts = value.is_a?(Array) ? value : [value]
  if texts.any? { |item| item.is_a?(String) && item.match?(PRIVATE_TEXT) }
    problems << "#{show(keys)} holds a local path, a credential, or an email address. Mark it private in #{sync_file}"
  elsif keys.any? { |key| key.match?(SECRET_NAME) }
    problems << "#{show(keys)} has a secret-like name. Mark it private in #{sync_file}"
  else
    store(output, keys, value)
  end
end

# Count the settings that no rule decides. Name only paths from SYNC_KEYS.
rules = public_rules + private_rules
new_paths = []
leaves(live) do |keys|
  next if keys.empty? || rules.any? { |rule| prefix?(rule, keys) }
  new_paths << keys
end
unless new_paths.empty?
  if option == '--show-new'
    warn 'save-settings: these settings are on neither list. The paths can hold private names; do not share them.'
    new_paths.each { |keys| warn "  #{keys.map { |key| ".\"#{key}\"" }.join}" }
  else
    groups = new_paths.group_by do |keys|
      known = (keys.length - 1).downto(1).find { |length| rules.any? { |rule| prefix?(keys[0, length], rule) } }
      known ? show(keys[0, known]) : 'the top level'
    end
    groups.each do |place, paths|
      warn "save-settings: #{paths.length} setting(s) under #{place} are on neither list and were not saved."
    end
    warn "save-settings: run ./bin/save-settings --show-new to list them, then mark each one in #{sync_file}."
  end
end

unless problems.empty?
  problems.uniq.each { |problem| warn "save-settings: #{problem}." }
  fail!("#{source_file} was not changed.")
end

File.write(output_file, JSON.pretty_generate(output) + "\n")
