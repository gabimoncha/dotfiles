typeset -U path
java_home="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home}"
android_sdk_home="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$java_home/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/scripts"
  "$android_sdk_home/emulator"
  "$android_sdk_home/platform-tools"
  "$path[@]"
)

unset java_home android_sdk_home
export PATH
