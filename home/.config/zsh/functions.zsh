dotfiles() {
  cd "${DOTFILES_ROOT:-$HOME/development/dotfiles}" || return
}

dotfiles-update() {
  "${DOTFILES_ROOT:-$HOME/development/dotfiles}/bin/dotfiles-update" "$@"
}

mkcd() {
  mkdir -p "$1" && cd "$1" || return
}

_claude_bin() {
  local bin="$HOME/.local/bin/claude"

  if [[ -x "$bin" ]]; then
    print -r -- "$bin"
    return 0
  fi

  command find /opt/homebrew/Caskroom/claude-code -maxdepth 2 -name claude -type f 2>/dev/null | command sort | command tail -1
}

claude() {
  local bin

  bin="$(_claude_bin)"
  if [[ -z "$bin" ]]; then
    print -u2 "claude: binary not found"
    return 1
  fi

  "$bin" --dangerously-skip-permissions "$@"
}

claude-safe() {
  local bin

  bin="$(_claude_bin)"
  if [[ -z "$bin" ]]; then
    print -u2 "claude: binary not found"
    return 1
  fi

  "$bin" "$@"
}

ports() {
  lsof -iTCP -sTCP:LISTEN -n -P
}

portfind() {
  if [[ -z "$1" ]]; then
    print "Usage: portfind <port>"
    print "Example: portfind 3000"
    return 1
  fi

  local results
  results="$(lsof -n -P -iTCP:"$1" 2>/dev/null)"
  if [[ -z "$results" ]]; then
    print "No process found on port $1"
    return 1
  fi

  print -r -- "$results"
}

killport() {
  if [[ -z "$1" ]]; then
    print "Usage: killport <port>"
    print "Example: killport 3000"
    return 1
  fi

  local -a pids
  pids=(${(f)"$(lsof -tiTCP:"$1" -sTCP:LISTEN 2>/dev/null)"})
  if (( ${#pids[@]} == 0 )); then
    print "No listening process found on port $1"
    return 1
  fi

  portfind "$1"
  print -n "Kill process(es) on port $1? [y/N] "
  read -r reply
  if [[ "$reply" != [Yy]* ]]; then
    print "Aborted."
    return 1
  fi

  kill "${pids[@]}"
}

fix-my-network() {
  local reset=$'\033[0m'
  local red=$'\033[0;31m'
  local green=$'\033[0;32m'
  local yellow=$'\033[1;33m'
  local blue=$'\033[0;34m'
  local issues=0
  local fixes=0

  _network_section() {
    print
    print "${blue}==> $1${reset}"
  }

  _network_ok() {
    print "ok  - $1"
  }

  _network_warn() {
    print "${yellow}warn - $1${reset}"
  }

  _network_fail() {
    print "${red}fail - $1${reset}"
    ((issues++))
  }

  _network_fixed() {
    print "${green}fix - $1${reset}"
    ((fixes++))
  }

  print "${blue}Network diagnostic and repair${reset}"

  _network_section "Proxy environment"
  local proxy_vars=(HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy FTP_PROXY ftp_proxy NO_PROXY no_proxy)
  local proxy_found=0
  local var
  for var in "${proxy_vars[@]}"; do
    if [[ -n "${(P)var}" ]]; then
      proxy_found=1
      _network_fail "found $var=${(P)var}"
      unset "$var"
      _network_fixed "cleared $var for this shell"
    fi
  done
  if (( proxy_found == 0 )); then
    _network_ok "no proxy variables set"
  fi

  _network_section "DNS"
  if nslookup google.com >/dev/null 2>&1; then
    _network_ok "google.com resolves"
  else
    _network_fail "google.com does not resolve"
    if sudo dscacheutil -flushcache 2>/dev/null && sudo killall -HUP mDNSResponder 2>/dev/null; then
      _network_fixed "flushed DNS cache"
    else
      _network_warn "could not flush DNS cache"
    fi
  fi

  local dns_server
  dns_server="$(scutil --dns 2>/dev/null | command awk '/nameserver\[[0-9]+\]/{print $3; exit}')"
  if [[ -n "$dns_server" ]]; then
    _network_ok "DNS server: $dns_server"
  else
    _network_warn "no DNS server reported by scutil"
  fi

  _network_section "Interface"
  local active_if=""
  local iface
  for iface in ${(s: :)$(ifconfig -l)}; do
    if ifconfig "$iface" 2>/dev/null | command grep -q "status: active"; then
      active_if="$iface"
      break
    fi
  done

  if [[ -n "$active_if" ]]; then
    local ip_addr
    ip_addr="$(ifconfig "$active_if" | command awk '/inet /{print $2; exit}')"
    _network_ok "active interface: $active_if ${ip_addr:+($ip_addr)}"
  else
    _network_fail "no active network interface found"
  fi

  _network_section "Connectivity"
  if ping -c 2 -W 2000 8.8.8.8 >/dev/null 2>&1; then
    _network_ok "raw IP ping works"
  else
    _network_fail "cannot reach 8.8.8.8"
  fi

  if ping -c 2 -W 2000 google.com >/dev/null 2>&1; then
    _network_ok "domain ping works"
  else
    _network_fail "cannot reach google.com"
  fi

  if curl -fsS --connect-timeout 5 https://example.com >/dev/null 2>&1; then
    _network_ok "HTTPS request works"
  else
    _network_fail "HTTPS request failed"
  fi

  _network_section "Routing and resources"
  local gateway
  gateway="$(netstat -rn 2>/dev/null | command awk '$1 == "default" && $2 !~ /:/{print $2; exit}')"
  if [[ -n "$gateway" ]]; then
    _network_ok "default gateway: $gateway"
  else
    _network_fail "no default gateway"
  fi

  local conn_count
  conn_count="$(lsof -i 2>/dev/null | wc -l | tr -d ' ')"
  _network_ok "open network rows: ${conn_count:-0} (fd limit: $(ulimit -n))"

  print
  if (( issues == 0 )); then
    print "${green}Network looks healthy.${reset}"
  else
    print "${yellow}Issues found: $issues; fixes applied: $fixes.${reset}"
    print "If it is still broken, check VPN/firewall settings and System Settings > Network."
  fi

  unfunction _network_section _network_ok _network_warn _network_fail _network_fixed
}

use-my-mac() {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "use-my-mac: fzf is required"
    return 1
  fi

  local selected command_line command_name
  selected="$(
    command cat <<'EOF' | fzf --height=80% --border --prompt="Search commands: " --header="enter: copy command, ctrl-e: execute, esc: quit" --preview='echo {}' --preview-window=up:3:wrap --bind='ctrl-e:execute-silent(echo {} | awk "{print \$1}" | pbcopy)+abort'
dotfiles             - cd to the dotfiles repo
dotfiles-update      - update dotfiles and Homebrew-owned tools
mkcd <dir>           - create a directory and cd into it
ll                   - list files with git status
la                   - list all files
tree                 - show tree excluding .git
myip                 - show public IP address
localip              - show local en0 IP address
ports                - list listening TCP ports
portfind <port>      - show the process using a port
killport <port>      - ask before killing a process listening on a port
fix-my-network       - diagnose common DNS, proxy, routing, and HTTP issues
cleanup              - delete .DS_Store files below the current directory
hosts                - edit /etc/hosts with nvim
brewup               - brew update, upgrade, and cleanup
claude               - run Claude with skipped permission prompts
claude-safe          - run Claude without skipped permission prompts
cc                   - short alias for claude
cc-safe              - short alias for claude-safe
use-my-mac           - open this searchable command menu
EOF
  )"

  [[ -z "$selected" ]] && return 0

  command_name="${selected%% *}"
  command_line="$command_name"
  print -n "$command_line" | pbcopy
  print "Copied to clipboard: $command_line"

  print -n "Execute now? [y/N] "
  read -r reply
  if [[ "$reply" != [Yy]* ]]; then
    return 0
  fi

  if [[ "$selected" == *"<"*">"* ]]; then
    print "Command needs an argument; complete it in your prompt."
    print -z "$command_line "
    return 0
  fi

  eval "$command_line"
}
