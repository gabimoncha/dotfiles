_dotfiles_check_updates() {
  local repo="${DOTFILES_ROOT:-$HOME/development/dotfiles}"
  local stamp="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/last-update-check"
  local now last

  [ -d "$repo/.git" ] || return 0
  mkdir -p "$(dirname "$stamp")"

  now="$(date +%s)"
  last="$(cat "$stamp" 2>/dev/null || printf 0)"
  [ $((now - last)) -lt 86400 ] && return 0
  printf '%s' "$now" > "$stamp"

  (
    git -C "$repo" fetch --quiet origin main 2>/dev/null || exit 0
    if ! git -C "$repo" merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
      printf '\nDotfiles updates are available. Run: dotfiles-update\n'
    fi
  ) &!
}

_dotfiles_check_updates
unfunction _dotfiles_check_updates 2>/dev/null || true
