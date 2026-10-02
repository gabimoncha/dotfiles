#!/usr/bin/env bash
# Vendor commands are resolved directly, never through mise shims.
harness_names=(codex claude pi t3 opencode cursor t3-desktop)

harness_binary() {
  case "$1" in
    codex) printf '%s/codex\n' "${CODEX_INSTALL_DIR:-$HOME/.local/bin}" ;;
    claude) printf '%s/.local/bin/claude\n' "$HOME" ;;
    pi) printf '%s/bin/pi\n' "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" ;;
    t3) printf '%s/t3\n' "${T3CODE_INSTALL_BIN_DIR:-$HOME/.local/bin}" ;;
    opencode) printf '%s/.opencode/bin/opencode\n' "$HOME" ;;
    cursor) printf '%s/.local/bin/agent\n' "$HOME" ;;
    t3-desktop)
      local candidate
      for candidate in "$(command -v brew || true)" /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -n "$candidate" && -x "$candidate" ]] || continue
        printf '%s\n' "$candidate"; return 0
      done
      return 1
      ;;
    *) return 2 ;;
  esac
}

harness_installed() {
  local executable root
  executable="$(harness_binary "$1")" || return 1
  [[ -x "$executable" ]] || return 1
  case "$1" in
    codex) root="${CODEX_HOME:-$HOME/.codex}/packages/standalone" ;;
    claude) root="$HOME/.local/share/claude" ;;
    pi)
      root="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
      [[ -f "$root/install/managed-install.json" ]] || return 1
      ;;
    t3) root="${T3CODE_HOME:-$HOME/.t3}/runtime/versions" ;;
    opencode) root="$HOME/.opencode/bin" ;;
    cursor) root="$HOME/.local/share/cursor-agent" ;;
    t3-desktop) "$executable" list --cask t3-code@nightly >/dev/null 2>&1; return $? ;;
  esac
  /usr/bin/ruby -e '
    executable, root = ARGV
    begin
      exit File.realpath(executable).start_with?(File.realpath(root) + "/") ? 0 : 1
    rescue SystemCallError
      exit 1
    end
  ' "$executable" "$root"
}

# The hook's PATH can put mise shims ahead of vendor commands. Node is still
# needed by Pi. Resolve an installed Node before removing shims from PATH.
harness_prepare_path() {
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
harness_probe() {
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
