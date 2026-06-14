typeset -U path
java_home="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home}"
android_sdk_home="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/usr/local/sbin"
  "$java_home/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/scripts"
  "$android_sdk_home/emulator"
  "$android_sdk_home/platform-tools"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  "$path[@]"
)

unset java_home android_sdk_home
export PATH
