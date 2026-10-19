[ -r "$HOME/.config/zsh/profile.zsh" ] && source "$HOME/.config/zsh/profile.zsh"

# profile.zsh already runs this. Vorssaint appends this exact line when it does
# not find it, which puts Homebrew ahead of ~/.local/bin. Keep it above the Codex block.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# >>> Codex installer >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Codex installer <<<
