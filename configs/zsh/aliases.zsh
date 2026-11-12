# Aliases for every shell, agents too, are in [shell_alias] in
# configs/mise/config/config.toml. Activation defines them. The shell that
# makes the Claude Code snapshot does not activate mise (mise-activate.zsh), so
# define them here from the list that mise prints. The snapshot records them.
if ((! ${+_dotfiles_mise_active} && $+commands[mise])); then
  command mise shell-alias ls --no-header 2>/dev/null | while read -r alias_name alias_command; do
    [[ -z "$alias_name" || -z "$alias_command" ]] || alias -- "$alias_name=$alias_command"
  done
  unset alias_name alias_command
fi

# The aliases below are for interactive zsh. The first ones replace a
# standard command, and agents write flags for the standard command. The
# Claude Code snapshot shell sources this file, so Claude Code has them too.
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
