#!/usr/bin/env bash
# The mise environment and the process checks of the container daemons, for
# bin/container-daemons, bin/t3-dev-supervise, bin/tokenburnmarket-supervise,
# and bin/setup-tokenburnmarket. Linux only.
#
# pgrep -f matches text anywhere in a command line, so it also finds an editor
# or a `watch` that names the same text. These checks read each argument from
# /proc instead, before a script signals a process.

# Gives this shell the mise environment of the container daemons: the user's
# own mise setup, MISE_ENV set to the layers and the role $1, such as
# devhost,devstation,container, and none of the caller's other MISE_*
# settings, such as those of ./bin/repo-mise. The caller sources
# dotfiles-profile.sh first. Call it in a subshell, or before exec.
daemon_env() {
  local name envs
  envs="$(dotfiles_profile_mise_env "$1")" || return
  for name in $(compgen -e); do
    case "$name" in MISE_*) unset "$name" ;; esac
  done
  export MISE_ENV="$envs"
}

# True while process $1 exists and is not a zombie. kill -0 succeeds for a
# zombie, which can no longer do any work.
proc_alive() {
  local stat
  stat="$(cat "/proc/$1/stat" 2>/dev/null)" || return 1
  stat="${stat##*) }"
  [[ -n "$stat" && "${stat%% *}" != Z ]]
}

# Prints the start time of process $1, in clock ticks after boot (field 22 of
# /proc/<pid>/stat). With the PID, it names one process, even after Linux
# gives the PID to a new process.
proc_start() {
  local stat
  stat="$(cat "/proc/$1/stat" 2>/dev/null)" || return 1
  stat="${stat##*) }"
  # shellcheck disable=SC2086 # Split the fields after the command name.
  set -- $stat
  [[ -n "${20:-}" ]] && printf '%s\n' "${20}"
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

# True when process $1 is bash running the script bin/$2 of a checkout, with
# no other arguments, as the shebang starts it.
supervise_pid() {
  proc_args "$1" || return 1
  [[ ${#proc_args[@]} == 2 && "${proc_args[0]##*/}" == bash && "${proc_args[1]}" == */bin/"$2" ]]
}

# True when process $1 is T3's service launcher: a t3 executable with the
# argument __service-launcher, run directly or by the shell of its shebang,
# as in `/bin/sh ~/.local/bin/t3 __service-launcher`. Another program with the
# same arguments, such as `watch`, does not match.
t3_launcher_pid() {
  proc_args "$1" || return 1
  [[ "${proc_args[0]##*/}" == t3 && "${proc_args[1]:-}" == __service-launcher ]] && return 0
  case "${proc_args[0]##*/}" in
    sh | dash | bash) ;;
    *) return 1 ;;
  esac
  [[ "${proc_args[1]:-}" == */t3 && "${proc_args[2]:-}" == __service-launcher ]]
}

# True when process $1 is a tokenburnmarket sync daemon: node runs the CLI's
# dist/index.js, directly or through a link such as its bin entry, with the
# command `daemon` and no subcommand. The entry point is node's first argument
# after its options. A relative one is resolved in the process's folder. The
# CLI's parser (dist/index.js parseArgs in 0.5.0) also accepts flags such as
# --interval 60 around the command.
tbm_daemon_pid() {
  local i=1 n arg entry real command="" subcommand=""
  proc_args "$1" || return 1
  n=${#proc_args[@]}
  [[ "${proc_args[0]##*/}" == node* ]] || return 1
  while ((i < n)); do
    case "${proc_args[i]}" in
      # Node options that take the next argument as their value.
      -r | --require | --import | --loader | --experimental-loader | -C | --conditions | --env-file | --title | --input-type)
        i=$((i + 2))
        continue
        ;;
      # Node runs code from the command line, not a file.
      -e | --eval | -p | --print | -) return 1 ;;
      --)
        i=$((i + 1))
        break
        ;;
      -*) ;;
      *) break ;;
    esac
    i=$((i + 1))
  done
  ((i < n)) || return 1
  entry="${proc_args[i]}"
  [[ "$entry" == /* ]] || entry="$(readlink "/proc/$1/cwd" 2>/dev/null)/$entry"
  # A daemon whose install mise has since removed keeps its path as written.
  real="$(readlink -f -- "$entry" 2>/dev/null)" || real=""
  case "${real:-$entry}" in
    */tokenburnmarket/dist/index.js | */bin/tokenburnmarket) ;;
    *) return 1 ;;
  esac
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
