# Activate mise in this shell: PATH gets the tool versions of the current
# folder, its [env], and its [shell_alias] aliases, and they change after `cd`.
# Tools then start directly, without a mise shim process per command.
# zshenv sources this for `zsh -c`, zprofile for `zsh -lc`, and interactive.zsh
# for interactive shells. Each shell activates once. A Claude Code shell gets
# the mise shims instead.

# Inside `mise exec TOOL@VERSION` or a mise task, PATH already has the versions
# that mise chose, and activation would replace them with the folder versions.
# __MISE_TASK_TOOL_ARGS is internal to mise: check it after a mise update.
[[ -n "${__MISE_TASK_TOOL_ARGS-}${MISE_TASK_NAME-}" ]] && return 0

# Claude Code runs each command in a `zsh -c` that reads zshenv and then the
# shell snapshot of the session. The snapshot ends with `export PATH=...`: the
# PATH of the Claude process, which Claude Code recorded when the session
# started. That line replaces the PATH of an activation, so the command gets
# the tool folders that the Claude process inherited, not those of its folder.
# A shim finds the version for the current folder each time a command runs.
# So these shells do not activate. They get the shims behind ~/bin and
# ~/.local/bin, and ahead of the mise/installs folders that are on PATH.
# claude-env.sh sources this file again after the snapshot, so this block has
# no guard. Claude Code runs claude-env.sh only when the Claude process has
# CLAUDE_ENV_FILE (env.zsh). Without it, for example in a session that started
# before env.zsh set the variable, the shell activates as usual. So does an
# interactive shell with CLAUDECODE, such as the terminal of an editor with
# the Claude Code extension.
if [[ -n "${CLAUDECODE-}" && ! -o interactive &&
  "${CLAUDE_ENV_FILE-}" == "$HOME/.config/zsh/claude-env.sh" ]]; then
  () {
    local -a front=("$HOME/bin" "$HOME/.local/bin" "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims")
    path=($front ${path:|front})
  }
  return 0
fi

((${+_dotfiles_mise_active})) && return 0
_dotfiles_mise_active=1

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
