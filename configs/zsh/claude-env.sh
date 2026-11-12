# shellcheck shell=sh
# Claude Code runs this text ahead of each Bash tool command, after it sources
# its shell snapshot (CLAUDE_ENV_FILE in env.zsh). The snapshot sets PATH to
# the PATH of the Claude process. mise-activate.zsh then puts the mise shims
# ahead of the mise/installs folders, so a tool has the version of its folder.
# Claude Code reads this file one time for each session. POSIX shell: Claude
# Code can also run bash.
[ -z "${ZSH_VERSION-}" ] || [ ! -r "$HOME/.config/zsh/mise-activate.zsh" ] || . "$HOME/.config/zsh/mise-activate.zsh"
