alias grep='rg'
alias cat='bat'
alias ls='eza'
alias ll='eza -la --git'
alias la='eza -a'
alias tree='tree -a -I .git'
alias g='git'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
