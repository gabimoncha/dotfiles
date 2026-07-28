# zsh requires this filename, but the real config lives under ~/.config/zsh.
[ -r "$HOME/.config/zsh/interactive.zsh" ] && source "$HOME/.config/zsh/interactive.zsh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/gabimoncha/.lmstudio/bin"
# End of LM Studio CLI section

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
