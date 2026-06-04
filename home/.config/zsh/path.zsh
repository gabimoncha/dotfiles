typeset -U path
android_sdk_home="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/scripts"
  "$android_sdk_home/emulator"
  "$android_sdk_home/platform-tools"
  "$path[@]"
)

unset android_sdk_home
export PATH
