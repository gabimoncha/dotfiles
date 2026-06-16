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

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

[ -r "$HOME/.config/zsh/path.zsh" ] && source "$HOME/.config/zsh/path.zsh"

if command -v mise >/dev/null 2>&1; then
  if mise_activate="$(mise activate zsh --no-hook-env 2>/dev/null)"; then
    eval "$mise_activate"
  fi
  unset mise_activate
fi

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-fzf-history-search)

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

true
