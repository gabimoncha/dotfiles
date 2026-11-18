#!/usr/bin/env bash
# Reads the T3 launcher file. Bash 3.2 compatible.
#
# Since 0.1.11-nightly.20261118.4877, T3's install.sh (launcher_script) and
# `t3 update` write ~/.local/bin/t3 as a shell file that runs
# `exec '<version folder>/t3' "$@"`, with each ' in the path written as '\''.
# Earlier versions wrote a link.

# Prints the runtime that the launcher file $1 runs. Fails when $1 is not that
# exact file, as T3's own readPosixLauncherTarget does. It never runs the file.
t3_launcher_target() {
  local launcher="$1" contents quoted runtime
  local head=$'#!/bin/sh\nexec \'' tail=$'\' "$@"\n' escaped="'\\''" sq="'"
  [[ -f "$launcher" && ! -L "$launcher" && "$(wc -c <"$launcher")" -le 4096 ]] || return 1
  # The x keeps the final newline through the command substitution.
  contents="$(
    cat "$launcher"
    printf x
  )" || return 1
  contents="${contents%x}"
  [[ "$contents" == "$head"*"$tail" ]] || return 1
  quoted="${contents#"$head"}"
  quoted="${quoted%"$tail"}"
  [[ "${quoted//"$escaped"/}" != *"'"* ]] || return 1
  runtime="${quoted//"$escaped"/$sq}"
  [[ -n "$runtime" ]] || return 1
  printf '%s\n' "$runtime"
}
