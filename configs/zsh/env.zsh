export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# ~/.config/mise links to configs/mise/config in the dotfiles checkout, so the
# link gives the checkout's path. The path is ~/code/personal/dotfiles.
if [[ -z "${DOTFILES_ROOT:-}" ]]; then
  DOTFILES_ROOT="${${:-$HOME/.config/mise}:A:h:h:h}"
  [[ -x "$DOTFILES_ROOT/bin/link-dotfiles" ]] || DOTFILES_ROOT="$HOME/code/personal/dotfiles"
fi
export DOTFILES_ROOT
# Pin installs like the config above. A process with a fake HOME would otherwise
# read the real config with no installs, and the gem shim would call itself forever.
export MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.rgrc}"
# Cargo caches compiler output through sccache, once mise has installed it.
[ ! -x "$MISE_DATA_DIR/shims/sccache" ] || export RUSTC_WRAPPER="${RUSTC_WRAPPER:-$MISE_DATA_DIR/shims/sccache}"
# The JDK that the global mise config selects. mise keeps this link on the
# installed version. Activated shells get the versioned path from mise.
export JAVA_HOME="${JAVA_HOME:-$MISE_DATA_DIR/installs/java/global}"
if [[ "$OSTYPE" == darwin* ]]; then
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
else
  export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
  # SSH commands start a non-login shell, which never reads path.zsh.
  typeset -U path
  path=("$HOME/bin" "$HOME/.local/bin" "$MISE_DATA_DIR/shims" "$ANDROID_HOME/platform-tools" $path)
fi
[ ! -r "$HOME/.config/zsh/telemetry.sh" ] || . "$HOME/.config/zsh/telemetry.sh"
