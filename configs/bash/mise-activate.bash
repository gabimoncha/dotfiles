# shellcheck shell=bash
# Activate mise in a bash shell: PATH gets the tool versions of the current
# folder, its [env], and its [shell_alias] aliases, and they change after `cd`.
# Bash reads no startup file for `bash -c`, so an agent that runs bash sources
# this file before each command. Pi does it through shellCommandPrefix in
# configs/pi/settings.json. Bash 3.2 compatible.
[ -n "${_dotfiles_mise_active-}" ] && return 0
_dotfiles_mise_active=1
# Inside `mise exec TOOL@VERSION` or a mise task, PATH already has the versions
# that mise chose, and activation would replace them with the folder versions.
# __MISE_TASK_TOOL_ARGS is internal to mise: check it after a mise update.
[ -n "${__MISE_TASK_TOOL_ARGS-}${MISE_TASK_NAME-}" ] && return 0
# A non-interactive bash expands aliases only with this option. An alias works
# from the next line of the command, and Pi puts the command on a new line.
shopt -s expand_aliases

_dotfiles_mise_bin="$HOME/.local/bin/mise"
[ -x "$_dotfiles_mise_bin" ] || _dotfiles_mise_bin="$(command -v mise 2>/dev/null || true)"
if [ -n "$_dotfiles_mise_bin" ]; then
  # mise puts its tool folders ahead of the folders that were on PATH when it
  # activated. Remove ~/bin and ~/.local/bin first and add them back after, so
  # the gh wrapper and the standalone agent CLIs stay first.
  _dotfiles_path=":$PATH:"
  _dotfiles_path="${_dotfiles_path//:$HOME\/bin:/:}"
  _dotfiles_path="${_dotfiles_path//:$HOME\/.local\/bin:/:}"
  _dotfiles_path="${_dotfiles_path#:}"
  PATH="${_dotfiles_path%:}"
  eval "$("$_dotfiles_mise_bin" activate bash)"
  PATH="$HOME/bin:$HOME/.local/bin:$PATH"
  unset _dotfiles_path
fi
unset _dotfiles_mise_bin
