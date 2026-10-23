#!/usr/bin/ruby
require 'json'
require 'open3'
require 'digest'
require 'fileutils'
require 'tmpdir'

# Only mise interprets declarations. This adapter selects native requests and
# keeps durable originals before mise changes live targets.
class DotfilesNative
  class Failure < StandardError; end

  def initialize(root, mode, telemetry)
    @root = File.realpath(root)
    @home = File.expand_path(ENV.fetch('HOME'))
    @mode = mode
    @telemetry = telemetry == '1'
    @mac = RUBY_PLATFORM.include?('darwin')
    @backups = {}
    @displaced = []
    @created = {}
    @directories = []
    @apply_started = false
  end

  def fail!(message)
    raise Failure, message
  end

  def native(*arguments, config: nil)
    loader = config ? ['--setup-config', config] : ['--setup']
    output, _, status = Open3.capture3(
      { 'MISE_VERBOSE' => '0', 'MISE_DEBUG' => '0', 'MISE_TRACE' => '0', 'NO_COLOR' => '1' },
      File.join(@root, 'bin/repo-mise'), *loader, *arguments
    )
    fail!('Native mise could not validate or apply the selection. Private diagnostics were omitted.') unless status.success?
    output
  end

  def path(value)
    fail!('A native path is invalid.') unless value.is_a?(String) && !value.empty? && !value.match?(/[\x00-\x1f]/)
    expanded = value.start_with?('~/') ? File.join(@home, value[2..-1]) : value
    fail!('A native path must be absolute.') unless expanded.start_with?('/')
    # Keep native source spelling. Resolving `..` before a parent symlink can
    # name a different file from the one mise reads or links.
    expanded
  end

  def exists?(target)
    File.exist?(target) || File.symlink?(target)
  end

  def inside?(target, directory)
    target == directory || target.start_with?(directory + '/')
  end

  def parent_path(target)
    parent = File.dirname(target)
    return File.join(File.realpath(parent), File.basename(target)) if File.directory?(parent)
    fail!('A target has a blocked parent directory.') if exists?(parent)
    File.join(parent_path(parent), File.basename(target))
  end

  def target_safe!(target)
    fail!('A native target is outside HOME.') unless inside?(target, @home) && target != @home
    actual = parent_path(target)
    fail!('A target parent points outside HOME or into this repository.') unless inside?(actual, File.realpath(@home)) && !inside?(actual, @root)
  end

  def selected?(row)
    target = path(row['target'] || row['path'])
    relative = target.sub(@home + '/', '')
    if @telemetry
      return %w[.config/telemetry/env.sh bin/dotfiles-telemetry-env Library/LaunchAgents/com.dotfiles.telemetry-env.plist].include?(relative) && (@mac || relative == '.config/telemetry/env.sh')
    end
    return false if ENV.fetch('DOTFILES_LINK_AGENT_CONFIG', '1') != '1' && (inside?(target, @home + '/.codex') || inside?(target, @home + '/.claude'))
    app = { '.aerospace.toml' => 'AeroSpace', 'Library/Application Support/com.mitchellh.ghostty/config' => 'Ghostty' }[relative]
    return false if app && !File.directory?(File.join(ENV.fetch('DOTFILES_APPLICATIONS_DIR', '/Applications'), app + '.app'))
    if relative == '.config/nvim'
      nvim = File.join(@root, 'nvim')
      return false unless File.directory?(nvim) && !(Dir.entries(nvim) - %w[. ..]).empty?
    end
    true
  end

  def declarations(config = nil)
    data = JSON.parse(native('dot', 'status', '--json', config: config))
    data.fetch('files').map { |row| row.merge('kind' => 'file') } + data.fetch('edits').map { |row| row.merge('kind' => 'edit') }
  end

  def validate_owners!(rows)
    owners = rows.group_by do |row|
      target = path(row['target'] || row['path'])
      target_safe!(target)
      parent_path(target)
    end
    owners.each_value do |entries|
      files = entries.count { |entry| entry['kind'] == 'file' }
      fail!('Multiple native declarations own the same target.') if files > 1 || (files == 1 && entries.size > 1)
      edits = entries.map { |entry| entry['edit'] }.compact
      fail!('Native merge IDs must be distinct for each target.') unless edits.uniq.size == edits.size
    end
    targets = owners.keys.sort
    targets.each_with_index do |target, index|
      fail!('Native target paths overlap.') if targets[(index + 1)..-1].any? { |other| inside?(other, target) }
    end
  end

  def selection
    # Native status combines owners by target or merge ID. Read each loaded
    # config separately before that combination can hide another owner.
    individual = @configs.flat_map do |config|
      fail!('Native ownership inspection loaded an unexpected configuration.') unless configuration(config) == [config]
      declarations(config)
    end
    validate_owners!(individual.select { |row| selected?(row) })
    rows = declarations
    rows.select! { |row| selected?(row) }
    rows.each do |row|
      row['absolute'] = path(row['target'] || row['path'])
      target_safe!(row['absolute'])
      fail!('A selected source or state is invalid.') unless %w[missing differs applied].include?(row['state'])
      if row['kind'] == 'file'
        fail!('The wrapper does not support this native file mode.') unless %w[symlink copy template].include?(row['mode'])
      else
        fail!('The wrapper supports only native merge edits.') unless row.fetch('edit').start_with?('merge:')
        fail!('A settings target must be a regular file, never a symlink.') if exists?(row['absolute']) && (!File.file?(row['absolute']) || File.symlink?(row['absolute']))
      end
      origin = row.fetch('origin')
      [row['source'], origin['source'], origin.fetch('config')].compact.each do |source|
        source = path(source)
        fail!('A selected source is missing or outside this repository.') unless File.exist?(source) && inside?(File.realpath(source), @root)
      end
    end
    validate_owners!(rows)
    rows.sort_by { |row| [row['absolute'], row['kind'], row['edit'].to_s] }
  end

  def signature(target, follow = false, seen = {})
    return ['missing'] unless exists?(target)
    stat = File.lstat(target)
    metadata = [stat.ftype, stat.dev, stat.ino, stat.mode, stat.size, stat.mtime.to_f, stat.ctime.to_f]
    if stat.symlink?
      link = File.readlink(target)
      return metadata + [link] unless follow
      real = File.realpath(target)
      fail!('A source directory contains a link cycle.') if seen[real]
      return metadata + [link, signature(real, true, seen.merge(real => true))]
    end
    if stat.file?
      metadata + [Digest::SHA256.file(target).hexdigest]
    elsif stat.directory?
      metadata + [Dir.entries(target).sort.reject { |name| %w[. ..].include?(name) || (follow && name == '.git') }.map { |name| [name, signature(File.join(target, name), follow, seen)] }]
    else
      fail!('A selected path has an unsupported file type.')
    end
  end

  def source_snapshot(rows)
    setup = File.join(@root, 'mise/setup')
    paths = %w[bin/repo-mise bin/link-t3-command bin/lib/dotfiles-profile.sh bin/lib/mise-pin.sh].map { |name| File.join(@root, name) } + @configs
    directories = @configs.map { |config| File.dirname(config) }
    rows.each do |row|
      origin = row.fetch('origin')
      paths.concat([row['source'], origin['source'], origin['config']].compact.map { |value| path(value) })
      # A global config can report HOME as config_root. Scan beside its
      # config file so live targets do not become source inputs.
      directories << File.dirname(path(origin.fetch('config')))
    end
    directories.uniq.each do |directory|
      # A module can own mise itself. Do not follow its setup/conf.d links
      # back into that module while recording template inputs.
      Dir.entries(directory).each do |name|
        input = File.join(directory, name)
        paths << input if File.file?(input)
      end
    end
    [[setup, signature(setup)]] + paths.uniq.sort.map { |source| [source, File.realpath(source), signature(source, true)] }
  end

  def configuration(config = nil)
    JSON.parse(native('config', '--json', config: config)).map do |entry|
      config = path(entry.fetch('path'))
      fail!('Setup loaded a configuration outside its isolated directory.') unless inside?(config, File.join(@root, 'mise/setup')) && inside?(File.realpath(config), @root)
      config
    end.sort
  end

  def shape(rows)
    rows.map { |row| row.reject { |key, _| %w[state reason omitted nested].include?(key) } }
  end

  def targets(rows)
    rows.map { |row| row['absolute'] }.uniq
  end

  def validate!(rows)
    return if rows.empty?
    # Force is confined to this read-only preview. Live apply always omits it.
    native('dot', 'apply', '--dry-run', '--force', '--yes', *targets(rows))
    # Diff renders templates that a dry run only lists. Capture the result so
    # settings and template error text cannot enter setup logs.
    native('dot', 'diff', *targets(rows))
    current = selection
    fail!('The native selection changed during validation. Rerun the command.') unless shape(current) == shape(rows)
    fail!('Native target states changed during validation. Rerun the command.') unless current.map { |row| row['state'] } == rows.map { |row| row['state'] }
    # A mise config target is read again during native apply. An isolated
    # setup loader must keep the same module selection across that reload.
    fail!('The sources changed during validation. Rerun the command.') unless source_snapshot(current) == @sources
  end

  def assert_unchanged!(rows, live = true)
    fail!('Native configuration reload changed the selected modules.') unless configuration == @configs
    fail!('The sources changed after validation. Rerun the command.') unless source_snapshot(rows) == @sources
    if live
      targets(rows).each { |target| fail!('A target changed after validation. Rerun the command.') unless signature(target) == @before.fetch(target) }
    end
    fail!('The native selection changed after validation. Rerun the command.') unless shape(selection) == shape(rows)
  end

  def backup_root
    return @backup_root if @backup_root
    parent = File.join(@home, '.dotfiles-backups')
    fail!('The backup directory must not be a symlink.') if File.symlink?(parent)
    FileUtils.mkdir_p(parent, :mode => 0700)
    File.chmod(0700, parent)
    @backup_root = Dir.mktmpdir('links-', parent)
    File.chmod(0700, @backup_root)
    File.open(parent, File::RDONLY) { |directory| directory.fsync }
    puts "Backups: #{@backup_root}"
    @backup_root
  end

  def remember(target, move)
    fail!('Refusing to overwrite an original backup.') if @backups.key?(target)
    destination = File.join(backup_root, format('%04d', @backups.size))
    fail!('Refusing to overwrite a backup path.') if exists?(destination)
    @backups[target] = { 'path' => destination, 'displaced' => move, 'ready' => false }
    write_manifest
    copied = !move
    if move
      @displaced << target
      begin
        File.rename(target, destination)
        @backups[target]['ready'] = true
      rescue Errno::EXDEV
        copied = true
      end
    end
    if copied
      original = signature(target)
      copy_original(target, destination)
      fail!('A target changed while its backup was copied.') unless signature(target) == original
      fail!('A backup does not match its original.') unless content_signature(target) == content_signature(destination)
    end
    @backups[target]['ready'] = true
    write_manifest
    if move && copied
      # The completed manifest must reach disk before the original is removed.
      fail!('A target changed before removal. Its completed backup is retained.') unless signature(target) == original
      begin
        FileUtils.remove_entry_secure(target)
      rescue SystemCallError, IOError
        fail!('The original could not be removed. Inspect the target and its completed backup before retrying.')
      end
    end
  end

  def write_manifest
    temporary = File.join(@backup_root, 'manifest.pending')
    File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, 0600) do |file|
      file.write(JSON.pretty_generate(@backups))
      file.flush
      file.fsync
    end
    File.rename(temporary, File.join(@backup_root, 'manifest.json'))
    File.open(@backup_root, File::RDONLY) { |directory| directory.fsync }
  end

  def content_signature(target)
    stat = File.lstat(target)
    if stat.symlink?
      ['symlink', stat.mode, File.readlink(target)]
    elsif stat.file?
      ['file', stat.mode, Digest::SHA256.file(target).hexdigest]
    elsif stat.directory?
      ['directory', stat.mode, Dir.entries(target).sort.reject { |name| %w[. ..].include?(name) }.map { |name| [name, content_signature(File.join(target, name))] }]
    else
      fail!('A backup has an unsupported file type.')
    end
  end

  def copy_original(source, destination)
    stat = File.lstat(source)
    if stat.symlink?
      File.symlink(File.readlink(source), destination)
      unless File.lstat(destination).mode == stat.mode
        begin
          File.lchmod(stat.mode & 07777, destination)
        rescue NotImplementedError, SystemCallError
          fail!('Symlink permissions could not be preserved. The original backup is incomplete.')
        end
      end
      return
    elsif stat.file?
      File.open(destination, File::WRONLY | File::CREAT | File::EXCL, 0600) do |output|
        File.open(source, File::RDONLY | File::NOFOLLOW) do |input|
          fail!('An original changed before it could be copied.') unless input.stat.dev == stat.dev && input.stat.ino == stat.ino
          IO.copy_stream(input, output)
        end
        output.flush
        output.fsync
      end
    elsif stat.directory?
      Dir.mkdir(destination, 0700)
      (Dir.entries(source) - %w[. ..]).each { |name| copy_original(File.join(source, name), File.join(destination, name)) }
    else
      fail!('An original has an unsupported file type.')
    end
    File.chmod(stat.mode & 07777, destination)
    File.utime(stat.atime, stat.mtime, destination)
    File.open(destination, File::RDONLY | File::NOFOLLOW) { |file| file.fsync }
  end

  def make_parents(target)
    parent = File.dirname(target)
    return if File.directory?(parent)
    make_parents(parent)
    Dir.mkdir(parent, 0700)
    @directories << parent
  end

  def precreate(target)
    return if exists?(target)
    make_parents(target)
    File.open(target, File::WRONLY | File::CREAT | File::EXCL, 0600) { |file| file.write(target.end_with?('.json') ? "{}\n" : '') }
    @created[target] = signature(target)
  end

  def git_value(target, key)
    output, _, status = Open3.capture3('git', 'config', '--file', target, '--get', key)
    status.success? ? output.strip : ''
  end

  def preserve_git_identity(rows)
    target = File.join(@home, '.gitconfig')
    return unless rows.any? { |row| row['absolute'] == target && row['state'] != 'applied' } && exists?(target)
    local = File.join(@home, '.gitconfig.local')
    target_safe!(local)
    fail!('The local Git identity must be a regular file.') if exists?(local) && (!File.file?(local) || File.symlink?(local))
    values = %w[user.name user.email].map { |key| [key, git_value(target, key)] }.reject { |key, value| value.empty? || !git_value(local, key).empty? }
    return if values.empty?
    if exists?(local)
      remember(local, false)
    else
      precreate(local)
    end
    values.each do |key, value|
      _, _, status = Open3.capture3('git', 'config', '--file', local, key, value)
      fail!('Git identity preservation failed. The original remains in the backup.') unless status.success?
    end
    File.chmod(0600, local)
    @created[local] = signature(local)
    puts 'Preserved the Git identity in ~/.gitconfig.local.'
  end

  def brew_link
    return if !@mac || @telemetry
    output, _, status = Open3.capture3('brew', '--prefix')
    return unless status.success?
    prefix = path(output.strip)
    source = File.join(@home, '.cli-proxy-api/config.yaml')
    return unless @rows.any? { |row| row['absolute'] == source } || File.exist?(source)
    target = File.join(prefix, 'etc/cliproxyapi.conf')
    actual = parent_path(target)
    fail!('The Homebrew config parent is unsafe.') unless inside?(actual, File.realpath(prefix)) && !inside?(actual, @root)
    @brew = { 'target' => target, 'source' => source, 'before' => signature(target) }
    return if File.symlink?(target) && File.readlink(target) == source
    puts "#{@mode == 'apply' ? 'Pending' : 'Would link'} #{target} -> #{source}"
  rescue Errno::ENOENT
    puts 'Skipping the CLIProxyAPI Homebrew config link. Homebrew is not installed.'
  end

  def apply_brew
    return unless @brew
    target, source = @brew.values_at('target', 'source')
    expected = @displaced.include?(target) ? ['missing'] : @brew['before']
    fail!('The Homebrew config target changed during apply.') unless signature(target) == expected
    return if File.symlink?(target) && File.readlink(target) == source
    fail!('The CLIProxyAPI config is missing after native apply.') unless File.exist?(source)
    make_parents(target)
    File.symlink(source, target)
  end

  def t3(dry_run)
    return unless @mac && !@telemetry
    args = [File.join(@root, 'bin/link-t3-command')]
    args << '--dry-run' if dry_run
    output, _, status = Open3.capture3(*args)
    puts output unless output.empty?
    warn 'The t3 command was not linked. Run ./bin/link-t3-command after you resolve the conflict.' unless status.success?
  end

  def recover
    @displaced.reverse_each do |target|
      entry = @backups.fetch(target)
      backup = entry['path']
      next unless entry['ready'] && exists?(backup)
      if exists?(target)
        row = @rows.find { |entry| entry['absolute'] == target }
        expected = row && row['mode'] == 'symlink' ? path(row['source']) : (@brew && @brew['target'] == target ? @brew['source'] : nil)
        if expected && File.symlink?(target) && File.readlink(target) == expected
          File.unlink(target)
        else
          warn "A partial change remains at #{target}. Its original backup is retained."
          next
        end
      end
      copy_original(backup, target)
      warn "Restored #{target}. The backup is retained."
    rescue StandardError
      warn "Could not restore #{target}. The original backup is retained."
    end
    @created.each do |target, state|
      next unless exists?(target) && signature(target) == state
      if @backups.key?(target)
        entry = @backups.fetch(target)
        next unless entry['ready'] && exists?(entry['path'])
        File.unlink(target)
        copy_original(entry['path'], target)
      elsif !@apply_started || !@rows.any? { |row| row['absolute'] == target }
        File.unlink(target)
      end
    rescue StandardError
      warn "Could not restore #{target}. Inspect the private backup."
    end
    @directories.reverse_each { |directory| Dir.rmdir(directory) rescue nil }
    warn 'Native apply can leave completed merges or copies in place. Inspect the targets and retained backups before retrying.' if @apply_started
  end

  def run
    File.umask(0077)
    if @mode == 'apply'
      %w[INT TERM].each { |signal| Signal.trap(signal) { raise Failure, 'Dotfile apply was interrupted. Inspect the retained backups before retrying.' } }
    end
    @configs = configuration
    @rows = selection
    @sources = source_snapshot(@rows)
    @before = targets(@rows).each_with_object({}) { |target, result| result[target] = signature(target) }
    validate!(@rows)
    assert_unchanged!(@rows)
    brew_link
    case @mode
    when 'status', 'diff', 'dry-run'
      @rows.each do |row|
        next if row['state'] == 'applied'
        label = row['kind'] == 'edit' ? 'merge; content omitted' : row.fetch('mode')
        puts format('%-10s %s (%s)', row['state'], row['target'] || row['path'], label)
        if @mode == 'diff' && row['kind'] == 'file'
          target = row['absolute']
          before = if File.symlink?(target)
            link = File.readlink(target)
            link.match?(/[\x00-\x1f]/) ? 'symlink; path omitted' : 'symlink to ' + link
          elsif exists?(target)
            File.lstat(target).ftype + '; content omitted'
          else
            'missing'
          end
          puts "  - #{before}"
          puts "  + #{row['mode']} from #{row['source']}"
        end
      end
      puts "#{@rows.count { |row| row['state'] == 'applied' }} of #{@rows.size} native files and merges are in place."
      puts 'Diff content is omitted to keep private settings out of logs.' if @mode == 'diff'
      t3(true)
      return @mode == 'status' && (@rows.any? { |row| row['state'] != 'applied' } || (@brew && !(File.symlink?(@brew['target']) && File.readlink(@brew['target']) == @brew['source']))) ? 1 : 0
    when 'apply'
      changing = @rows.reject { |row| row['state'] == 'applied' }
      # All sources, merges, and live targets passed validation before any
      # original can move. Each original target has one backup slot.
      changing.select { |row| row['kind'] == 'edit' }.map { |row| row['absolute'] }.uniq.each do |target|
        remember(target, false) if exists?(target)
      end
      assert_unchanged!(@rows)
      preserve_git_identity(@rows)
      changing.select { |row| row['kind'] == 'file' }.each do |row|
        target = row['absolute']
        fail!('A target changed before backup.') unless signature(target) == @before.fetch(target)
        remember(target, true) if exists?(target)
      end
      if @brew && !(File.symlink?(@brew['target']) && File.readlink(@brew['target']) == @brew['source'])
        fail!('The Homebrew config target changed before backup.') unless signature(@brew['target']) == @brew['before']
        remember(@brew['target'], true) if exists?(@brew['target'])
      end
      changing.select { |row| row['kind'] == 'edit' }.map { |row| row['absolute'] }.uniq.each { |target| precreate(target) }
      assert_unchanged!(@rows, false)
      prepared = targets(@rows).each_with_object({}) do |target, result|
        expected = if @displaced.include?(target)
          ['missing']
        elsif @created.key?(target)
          @created.fetch(target)
        else
          @before.fetch(target)
        end
        fail!('A target changed before native apply.') unless signature(target) == expected
        result[target] = expected
      end
      # Recheck the selected apply against the prepared targets, without force.
      native('dot', 'apply', '--dry-run', '--yes', *targets(@rows)) unless @rows.empty?
      assert_unchanged!(@rows, false)
      prepared.each { |target, state| fail!('A target changed before native apply.') unless signature(target) == state }
      @apply_started = true
      native('dot', 'apply', '--yes', *targets(@rows)) unless @rows.empty?
      after = selection
      fail!('Native configuration reload changed the selected modules.') unless configuration == @configs
      fail!('Native configuration reload changed the selected owners.') unless shape(after) == shape(@rows)
      fail!('Native apply left selected targets out of date.') unless after.all? { |row| row['state'] == 'applied' }
      apply_brew
      t3(false)
      puts 'Native dotfiles are in place.'
      0
    else
      fail!('Unknown link-dotfiles operation.')
    end
  rescue Failure
    recover if @mode == 'apply'
    raise
  rescue StandardError
    recover if @mode == 'apply'
    fail!('The operation stopped. Private diagnostics were omitted. Inspect the selected paths and any retained backups.')
  end
end

begin
  exit DotfilesNative.new(*ARGV).run
rescue DotfilesNative::Failure => error
  warn error.message
  exit 1
end
