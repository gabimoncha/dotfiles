# Shared interactive zsh configuration.

export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/development/dotfiles}"

typeset -A dotfiles_sourced_local_configs
for local_config in "$HOME"/.config/local/*.zsh(N) "${DOTFILES_ROOT}"/home/.config/local/*.zsh(N); do
  local_config_real="${local_config:A}"
  if [[ -n "${dotfiles_sourced_local_configs[$local_config_real]-}" ]]; then
    continue
  fi

  dotfiles_sourced_local_configs[$local_config_real]=1
  [ -r "$local_config" ] && source "$local_config"
done
unset local_config local_config_real dotfiles_sourced_local_configs

for brew_bin in "${commands[brew]-}" /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -n "$brew_bin" && -x "$brew_bin" ]] || continue
  eval "$("$brew_bin" shellenv 2>/dev/null)"
  break
done
unset brew_bin

[ -r "$HOME/.config/zsh/path.zsh" ] && source "$HOME/.config/zsh/path.zsh"

# Static shims avoid invoking mise or credentials during prompt initialization.
# Missing tools are installed only by an explicit setup/update command.
_dotfiles_real_tool() {
  local candidate="${commands[$1]-}"
  local mise_root="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  case "$candidate" in
    */mise/shims/*|"$mise_root"/shims/*)
      local installed=("$mise_root"/installs/*/*/bin/"$1"(N-om))
      candidate=""
      local executable
      for executable in "$installed[@]"; do
        [[ -x "$executable" ]] || continue
        candidate="$executable"
        break
      done
      [[ -n "$candidate" ]] || return 1
      ;;
  esac
  print -r -- "$candidate"
}
path=("$HOME/bin" "$HOME/.local/bin" $path)

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""
plugins=(git)
[[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && plugins+=(zsh-autosuggestions)
if fzf_bin="$(_dotfiles_real_tool fzf)" && [[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh" ]]; then
  # The plugin may invoke fzf while loading; give it the installed executable.
  path=("$HOME/bin" "$HOME/.local/bin" "${fzf_bin:h}" $path)
  plugins+=(zsh-fzf-history-search)
fi
unset fzf_bin

if [ -r "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [ -r "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi

[ -r "$HOME/.config/zsh/aliases.zsh" ] && source "$HOME/.config/zsh/aliases.zsh"
[ -r "$HOME/.config/zsh/mise-npx.zsh" ] && source "$HOME/.config/zsh/mise-npx.zsh"
[ -r "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"
[ -r "$HOME/.config/zsh/check-updates.zsh" ] && source "$HOME/.config/zsh/check-updates.zsh"
[ -r "$HOME/.p10k.zsh" ] && source "$HOME/.p10k.zsh"

# Optional plugins must not displace standalone-managed commands.
path=("$HOME/bin" "$HOME/.local/bin" $path)
true
