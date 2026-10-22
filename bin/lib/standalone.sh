#!/usr/bin/env bash
# Reads apps/standalone.tsv. Bash 3.2 compatible. Callers set repo_root.
# Vendor commands are resolved directly, never through mise shims.
standalone_manifest="${repo_root}/apps/standalone.tsv"
# shellcheck source=bin/lib/mise-pin.sh
. "${repo_root}/bin/lib/mise-pin.sh"

standalone_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux) printf 'linux\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

# Expands ~ and the vendor overrides: MISE_INSTALL_PATH, CODEX_INSTALL_DIR,
# CODEX_HOME, and PI_CODING_AGENT_DIR.
standalone_expand() {
  local path="$1"
  case "$path" in
    '~/.local/bin/mise') [[ -n "${MISE_INSTALL_PATH:-}" ]] && path="$MISE_INSTALL_PATH" ;;
    '~/.local/bin/codex') [[ -n "${CODEX_INSTALL_DIR:-}" ]] && path="${CODEX_INSTALL_DIR}/codex" ;;
  esac
  case "$path" in
    '~/.codex'*) [[ -n "${CODEX_HOME:-}" ]] && path="${CODEX_HOME}${path#\~/.codex}" ;;
    '~/.pi/agent'*) [[ -n "${PI_CODING_AGENT_DIR:-}" ]] && path="${PI_CODING_AGENT_DIR}${path#\~/.pi/agent}" ;;
  esac
  case "$path" in
    '~/'*) path="${HOME}/${path#\~/}" ;;
  esac
  printf '%s\n' "$path"
}

# Prints this OS's rows as: name, phase, command, root, installer, update.
standalone_rows() {
  local os name row_os phase command root installer update
  os="$(standalone_os)"
  while IFS=$'\t' read -r name row_os phase command root installer update || [[ -n "${name:-}" ]]; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    [[ "$row_os" == all || "$row_os" == "$os" ]] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$phase" \
      "$(standalone_expand "$command")" "$(standalone_expand "$root")" "$installer" "$update"
  done < "$standalone_manifest"
}

standalone_names() { standalone_rows | cut -f1; }

# Prints one field of a row: phase, command, root, installer, or update.
standalone_field() {
  local name="$1" field="$2" column
  case "$field" in
    phase) column=2 ;; command) column=3 ;; root) column=4 ;; installer) column=5 ;; update) column=6 ;;
    *) return 2 ;;
  esac
  standalone_rows | awk -F '\t' -v name="$name" -v column="$column" '$1 == name { print $column; found = 1 } END { exit found ? 0 : 1 }'
}

standalone_realpath() {
  /usr/bin/ruby -e '
    begin
      print File.realpath(ARGV.fetch(0))
    rescue SystemCallError
      exit 1
    end
  ' "$1"
}

# Succeeds when the vendor install owns the command. It does not run the tool.
standalone_installed() {
  local name="$1" command root real
  command="$(standalone_field "$name" command)" || return 1
  root="$(standalone_field "$name" root)" || return 1
  [[ -x "$command" ]] || return 1
  real="$(standalone_realpath "$command")" || return 1
  case "$name" in
    mise)
      # The standalone installer writes a regular file. A link can point at a
      # Homebrew mise, which has no self-update.
      [[ ! -L "$command" && "$real" != */Cellar/* ]] || return 1
      mise_at_pin "$command" || return 1
      MISE_SELF_UPDATE_AUTO=0 "$command" self-update --help >/dev/null 2>&1
      return
      ;;
    pi) [[ -f "$root/install/managed-install.json" ]] || return 1 ;;
    cursor)
      # The installer creates both names; callers use either one.
      local alias_real
      alias_real="$(standalone_realpath "$(dirname "$command")/cursor-agent")" || return 1
      [[ "$alias_real" == "$(standalone_realpath "$root")/"* && -f "$alias_real" && -x "$alias_real" ]] || return 1
      ;;
  esac
  root="$(standalone_realpath "$root")" || return 1
  [[ "$real" == "$root/"* ]]
}

# The hook's PATH can put mise shims ahead of vendor commands. Pi still needs
# Node, so resolve an installed Node before removing shims from PATH.
standalone_prepare_path() {
  local node_path entry filtered="" entries=()
  node_path="$(command -v node || true)"
  case "$node_path" in
    */shims/*)
      node_path="$(MISE_AUTO_INSTALL=0 MISE_OFFLINE=1 mise which node 2>/dev/null || true)"
      ;;
  esac
  IFS=: read -r -a entries <<< "$PATH"
  for entry in "${entries[@]}"; do
    [[ -n "$entry" ]] || continue
    case "$entry" in */shims) continue ;; esac
    filtered="${filtered:+$filtered:}$entry"
  done
  export PATH="${HOME}/.local/bin:${HOME}/.opencode/bin:${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/bin:${filtered}"
  if [[ -n "$node_path" && -x "$node_path" && "$node_path" != */shims/* ]]; then
    export PATH="$(dirname "$node_path"):$PATH"
  fi
  export MISE_AUTO_INSTALL=0
}

# Bound health probes so a broken command cannot stall setup indefinitely.
standalone_probe() {
  local timeout="${DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS:-10}"
  [[ "$timeout" =~ ^[1-9][0-9]*$ ]] || return 2
  /usr/bin/ruby -e '
    seconds = Integer(ARGV.shift)
    pid = Process.spawn(*ARGV, pgroup: true)
    stop = lambda do |code|
      begin; Process.kill("TERM", -pid); rescue Errno::ESRCH; end
      sleep 0.2
      begin; Process.kill("KILL", -pid); rescue Errno::ESRCH; end
      begin; Process.wait(pid); rescue Errno::ECHILD; end
      exit code
    end
    Signal.trap("ALRM") { stop.call(124) }
    Signal.trap("INT") { stop.call(130) }
    Signal.trap("TERM") { stop.call(143) }
    watchdog = Thread.new { sleep seconds; Process.kill("ALRM", Process.pid) }
    _, status = Process.wait2(pid)
    watchdog.kill
    exit(status.signaled? ? 128 + status.termsig : status.exitstatus)
  ' "$timeout" "$@" </dev/null
}

# macOS ships shasum; Debian ships sha256sum. Absolute paths come first, so a
# mise shim cannot answer while mise itself is missing.
standalone_sha256() {
  local output
  if [[ -x /usr/bin/shasum ]]; then
    output="$(/usr/bin/shasum -a 256 "$1")" || return
  elif [[ -x /usr/bin/sha256sum ]]; then
    output="$(/usr/bin/sha256sum "$1")" || return
  else
    printf '!! No SHA-256 tool found (shasum or sha256sum)\n' >&2
    return 1
  fi
  printf '%s\n' "${output%% *}"
}
