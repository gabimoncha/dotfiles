dotfiles() {
  cd "${DOTFILES_ROOT:-$HOME/development/dotfiles}" || return
}

dotfiles-update() {
  "${DOTFILES_ROOT:-$HOME/development/dotfiles}/bin/dotfiles-update" "$@"
}

mkcd() {
  mkdir -p "$1" && cd "$1" || return
}
