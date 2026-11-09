# Aliases for every shell, agents too, are in [shell_alias] in
# configs/mise/config/config.toml. Only interactive zsh gets these aliases.
# The first ones replace a standard command, and agents write flags for the
# standard command.
if (($+commands[rg])); then alias grep='rg'; fi
if (($+commands[bat])); then alias cat='bat'; fi
if (($+commands[eza])); then alias ls='eza'; fi
alias tree='tree -a -I .git'

# Socket Firewall checks each package that these managers download. It adds
# about 0.4 s and a node process to each call, so agent shells skip it.
if (($+commands[sfw])); then
  alias npm='sfw npm'
  alias pnpm='sfw pnpm'
  alias yarn='sfw yarn'
  alias pip='sfw pip'
  alias uv='sfw uv'
  alias cargo='sfw cargo'
fi

if zoxide_bin="$(_dotfiles_real_tool zoxide)"; then
  eval "$("$zoxide_bin" init zsh 2>/dev/null)"
fi
unset zoxide_bin
