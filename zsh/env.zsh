export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# Pin installs like the config above. A process with a fake HOME would otherwise
# read the real config with no installs, and the gem shim would call itself forever.
export MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.rgrc}"
# Cargo caches compiler output through sccache, once mise has installed it.
[ ! -x "$MISE_DATA_DIR/shims/sccache" ] || export RUSTC_WRAPPER="${RUSTC_WRAPPER:-$MISE_DATA_DIR/shims/sccache}"
if [[ "$OSTYPE" == darwin* ]]; then
  export JAVA_HOME="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home}"
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
else
  # SSH commands start a non-login shell, which never reads path.zsh.
  typeset -U path
  path=("$HOME/bin" "$HOME/.local/bin" "$MISE_DATA_DIR/shims" $path)
fi
[ ! -r "$HOME/.config/telemetry/env.sh" ] || . "$HOME/.config/telemetry/env.sh"
