typeset -U path

if [[ "$OSTYPE" == darwin* ]]; then
  java_home="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home}"
  android_sdk_home="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
    "$HOME/.pi/agent/bin"
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
else
  # Linux images put tools in /usr/local/bin (the Node image has node and npm),
  # so the mise versions go ahead of it.
  path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
    "$HOME/.opencode/bin"
    "$HOME/.pi/agent/bin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    "$path[@]"
  )
fi

export PATH="$HOME/.bun/bin:$PATH"

export PATH
