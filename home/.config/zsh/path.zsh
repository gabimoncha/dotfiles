typeset -U path

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/scripts"
  "$path[@]"
)

export PATH
