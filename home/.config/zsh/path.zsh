typeset -U path

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/scripts"
  "$path[@]"
)

export PATH
