# Activate mise in this shell: PATH gets the tool versions of the current
# folder, its [env], and its [shell_alias] aliases, and they change after `cd`.
# Tools then start directly, without a mise shim process per command.
# zshenv sources this for `zsh -c`, zprofile for `zsh -lc`, and interactive.zsh
# for interactive shells. Each shell activates once.
((${+_dotfiles_mise_active})) && return 0
_dotfiles_mise_active=1
# Inside `mise exec TOOL@VERSION` or a mise task, PATH already has the versions
# that mise chose, and activation would replace them with the folder versions.
# __MISE_TASK_TOOL_ARGS is internal to mise: check it after a mise update.
[[ -n "${__MISE_TASK_TOOL_ARGS-}${MISE_TASK_NAME-}" ]] && return 0

() {
  local mise_bin="$HOME/.local/bin/mise" dir
  [[ -x "$mise_bin" ]] || mise_bin="${commands[mise]-}"
  [[ -n "$mise_bin" ]] || return 0
  # mise puts its tool folders ahead of the folders that were on PATH when it
  # activated. Remove ~/bin and ~/.local/bin first and add them back after, so
  # the gh wrapper and the standalone agent CLIs stay first.
  local -a keep
  for dir in $path; do
    [[ "$dir" == "$HOME/bin" || "$dir" == "$HOME/.local/bin" ]] || keep+=("$dir")
  done
  path=($keep)
  eval "$("$mise_bin" activate zsh)"
  path=("$HOME/bin" "$HOME/.local/bin" $path)
}
