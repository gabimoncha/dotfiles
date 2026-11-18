#!/usr/bin/env bash
# The mise environment and the process checks of the container daemons, for
# bin/container-daemons, bin/t3-dev-supervise, bin/tokenburnmarket-supervise,
# and bin/setup-tokenburnmarket. Linux only.
#
# pgrep -f matches text anywhere in a command line, so it also finds an editor
# or a `watch` that names the same text. These checks read each argument from
# /proc instead, before a script signals a process.

# Gives this shell the mise environment of the container daemons: the user's
# own mise setup, MISE_ENV set to the profile $1, and none of the caller's
# other MISE_* settings, such as those of ./bin/repo-mise. Call it in a
# subshell, or before exec.
daemon_env() {
  local name
  for name in $(compgen -e); do
    case "$name" in MISE_*) unset "$name" ;; esac
  done
  export MISE_ENV="$1"
}

# True while process $1 exists and is not a zombie. kill -0 succeeds for a
# zombie, which can no longer do any work.
proc_alive() {
  local stat
  stat="$(cat "/proc/$1/stat" 2>/dev/null)" || return 1
  stat="${stat##*) }"
  [[ -n "$stat" && "${stat%% *}" != Z ]]
}

# Reads the arguments of process $1 into the array proc_args. Returns 1 when
# the process is gone or has no arguments, as a zombie has none.
proc_args() {
  local arg
  proc_args=()
  [[ -r "/proc/$1/cmdline" ]] || return 1
  {
    while IFS= read -r -d '' arg; do
      proc_args+=("$arg")
    done <"/proc/$1/cmdline"
  } 2>/dev/null
  ((${#proc_args[@]} > 0))
}

# True when process $1 is bash running the script bin/$2 of a checkout.
supervise_pid() {
  local n
  proc_args "$1" || return 1
  n=${#proc_args[@]}
  ((n >= 2)) || return 1
  [[ "${proc_args[n - 1]}" == */bin/"$2" && "${proc_args[n - 2]##*/}" == bash ]]
}

# True when process $1 is T3's service launcher: a t3 executable, run directly
# or by an interpreter, with the argument __service-launcher.
t3_launcher_pid() {
  proc_args "$1" || return 1
  [[ "${proc_args[0]##*/}" == t3 && "${proc_args[1]:-}" == __service-launcher ]] && return 0
  [[ "${proc_args[1]:-}" == */t3 && "${proc_args[2]:-}" == __service-launcher ]]
}

# True when process $1 is a tokenburnmarket sync daemon: node runs the CLI,
# through its bin link or its dist/index.js, with the command `daemon` and no
# subcommand. Node options can come before the CLI path. The CLI's parser
# (dist/index.js parseArgs in 0.5.0) also accepts flags such as --interval 60
# around the command.
tbm_daemon_pid() {
  local i=1 n arg command="" subcommand=""
  proc_args "$1" || return 1
  n=${#proc_args[@]}
  [[ "${proc_args[0]##*/}" == node* ]] || return 1
  while ((i < n)); do
    case "${proc_args[i]}" in
      */tokenburnmarket | */tokenburnmarket/dist/index.js) break ;;
    esac
    i=$((i + 1))
  done
  ((i < n)) || return 1
  i=$((i + 1))
  while ((i < n)); do
    arg="${proc_args[i]}"
    case "$arg" in
      --server | --name | --since | --interval | -server | -name | -since | -interval)
        [[ "${proc_args[i + 1]:-}" == -* ]] || i=$((i + 1))
        ;;
      -*) ;;
      *)
        if [[ -z "$command" ]]; then
          command="$arg"
        elif [[ -z "$subcommand" ]]; then
          subcommand="$arg"
        fi
        ;;
    esac
    i=$((i + 1))
  done
  [[ "$command" == daemon && -z "$subcommand" ]]
}

# Sets the array matched to the PIDs of this user's processes that pgrep finds
# for pattern $1 and that check $2 accepts. Extra arguments go to the check
# after the PID. The caller and its subshells never match. Call it without
# $(...): a subshell is a copy of the caller's script while it runs.
matching_pids() {
  local pattern="$1" check="$2" p pids
  shift 2
  matched=()
  # pgrep is the only command in $(...), so bash runs it in place of the copy.
  pids="$(pgrep -u "$(id -u)" -f -- "$pattern")" || return 0
  for p in $pids; do
    [[ "$p" != "$$" && "$p" != "$BASHPID" ]] || continue
    if "$check" "$p" "$@"; then matched+=("$p"); fi
  done
  return 0
}
