alias grep='rg'
alias cat='bat'
alias ls='eza'
alias ll='eza -la --git'
alias la='eza -a'
alias tree='tree -a -I .git'
alias g='git'
alias myip='curl ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias cleanup='find . -name ".DS_Store" -delete'
alias hosts='sudo nvim /etc/hosts'
alias brewup='brew update && brew upgrade && brew cleanup'
alias help='use-my-mac'
alias c='cursor'
alias cc='claude'
alias cc-safe='claude-safe'
alias n='nvim'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
