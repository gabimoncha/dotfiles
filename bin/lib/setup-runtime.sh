#!/usr/bin/env bash
# Bash 3.2 compatible. Never enable xtrace here: credentials may be in memory.
runtime_sanitize() {
  /usr/bin/ruby -e '
    STDOUT.sync = true
    STDIN.each_line do |line|
      line = line.scrub
      line.gsub!(/(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9_-]{12,})/, "[REDACTED]")
      line.gsub!(/((?:authorization|token|password|passwd|secret|api[_-]?key)"?\s*[=:]\s*"?)(?:Bearer\s+)?\S+/i) { "#{$1}[REDACTED]" }
      line.gsub!(/\bBearer\s+[A-Za-z0-9._~+\/-]+/i, "Bearer [REDACTED]")
      line.gsub!(%r{https://[^/\s:@]+:[^/\s@]+@}, "https://[REDACTED]@")
      print line
    end
  '
}
runtime_stream_output() {
  local line
  # Shell printf writes each line immediately, including an unterminated tail.
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s\n' "$line" >&3
    printf '[%s] %s\n' "$2" "$line"
  done 3> "$1"
}
runtime_json() {
  runtime_sanitize | /usr/bin/ruby -rjson -e 'print JSON.generate(STDIN.read.scrub)[1...-1]'
}
runtime_sanitize_name() { printf '%s' "$1" | tr -c '[:alnum:]._' '-'; }
runtime_log() { printf '==> %s\n' "$1"; }
runtime_warn() { printf '!! %s\n' "$1" >&2; }
runtime_event() {
  local event="$1" id="${2:-${DOTFILES_STAGE_ID:-setup}}" parent="${3-setup}" outcome="${4:-}" status="${5:-0}" detail="${6:-}" prerequisites="${7:-}" duration="${8:-0}" stack="${9:-}"
  local stream="${DOTFILES_SETUP_LOG_DIR}/streams/${DOTFILES_RUNTIME_PID:-$$}.${DOTFILES_RUNTIME_STREAM_ID}.jsonl" record
  record="$(printf '{"timestamp":"%s","mode":"%s","event":"%s","stage_id":"%s","parent_stage_id":"%s","prerequisites":"%s","outcome":"%s","exit_status":%s,"duration_seconds":%s,"detail":"%s","stack":"%s"}' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DOTFILES_RUN_MODE" "$event" "$(printf '%s' "$id" | runtime_json)" "$(printf '%s' "$parent" | runtime_json)" "$(printf '%s' "$prerequisites" | runtime_json)" "$outcome" "$status" "$duration" "$(printf '%s' "$detail" | runtime_json)" "$(printf '%s' "$stack" | runtime_json)")"
  printf '%s\n' "$record" >> "$stream"
}
runtime_merge_trace() {
  local temporary="${DOTFILES_SETUP_LOG_DIR}/events.${DOTFILES_RUNTIME_PID:-$$}.${RANDOM}.tmp"
  cat "$DOTFILES_SETUP_LOG_DIR"/streams/*.jsonl > "$temporary"
  mv "$temporary" "$DOTFILES_SETUP_LOG_DIR/events.jsonl"
}
runtime_init() {
  [[ "${DOTFILES_RUNTIME_INITIALIZED:-0}" == 1 ]] && return 0
  DOTFILES_RUNTIME_INITIALIZED=1
  DOTFILES_RUNTIME_PID="$(sh -c 'echo "$PPID"')"
  DOTFILES_RUNTIME_SCRIPT="${1:-setup}"
  DOTFILES_RUN_MODE="${2:-${DOTFILES_RUN_MODE:-normal}}"
  DOTFILES_RUNTIME_STREAM_ID="${RANDOM}.${RANDOM}"
  DOTFILES_RUNTIME_OWNS_SUMMARY=0
  DOTFILES_RUNTIME_OWNS_LOG_DIR=0
  DOTFILES_RUNTIME_CANCELLED=0
  DOTFILES_RUNTIME_CLEANED=0
  DOTFILES_RUNTIME_LOCK_ROOT="${DOTFILES_RUNTIME_LOCK_ROOT:-${TMPDIR:-/tmp}/dotfiles-locks-${UID}}"
  DOTFILES_RUNTIME_HELD_LOCKS=()
  DOTFILES_JOB_PIDS=(); DOTFILES_JOB_NAMES=(); DOTFILES_JOB_SEVERITIES=(); DOTFILES_JOB_FIXES=(); DOTFILES_JOB_LOGS=(); DOTFILES_JOB_STARTS=(); DOTFILES_JOB_IDS=(); DOTFILES_JOB_PARENTS=(); DOTFILES_JOB_PREREQS=(); DOTFILES_JOB_FAILED=0
  umask 077
  if [[ -z "${DOTFILES_SETUP_LOG_DIR:-}" ]]; then
    local root="${DOTFILES_SETUP_RUN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.local/setup-runs}"
    mkdir -p "$root"
    DOTFILES_SETUP_LOG_DIR="$(mktemp -d "$root/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
    DOTFILES_RUNTIME_OWNS_LOG_DIR=1
    DOTFILES_RUNTIME_OWNS_SUMMARY=1
  fi
  mkdir -p "$DOTFILES_SETUP_LOG_DIR/streams"
  chmod 700 "$DOTFILES_SETUP_LOG_DIR" "$DOTFILES_SETUP_LOG_DIR/streams"
  DOTFILES_SETUP_SUMMARY_FILE="${DOTFILES_SETUP_SUMMARY_FILE:-$DOTFILES_SETUP_LOG_DIR/summary.txt}"
  touch "$DOTFILES_SETUP_SUMMARY_FILE" "$DOTFILES_SETUP_LOG_DIR/events.jsonl"
  chmod 600 "$DOTFILES_SETUP_SUMMARY_FILE" "$DOTFILES_SETUP_LOG_DIR/events.jsonl"
  export DOTFILES_SETUP_LOG_DIR DOTFILES_SETUP_SUMMARY_FILE DOTFILES_RUN_MODE
  runtime_log "Diagnostic logs: $DOTFILES_SETUP_LOG_DIR"
  local commit dirty metadata_root
  metadata_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  commit="$(git -C "$metadata_root" rev-parse HEAD 2>/dev/null || printf unknown)"
  dirty="$( (git -C "$metadata_root" status --porcelain --untracked-files=normal 2>/dev/null || true) | wc -l | tr -d ' ')"
  runtime_event run_start "$DOTFILES_RUNTIME_SCRIPT" "" "" 0 "commit=$commit dirty_count=$dirty"
  runtime_merge_trace
  trap 'runtime_signal INT 130' INT
  trap 'runtime_signal TERM 143' TERM
  trap 'runtime_on_exit $?' EXIT
}
runtime_stack() {
  local i
  for ((i=1; i<${#FUNCNAME[@]}; i++)); do
    printf '%s:%s:%s\n' "${BASH_SOURCE[$i]:-unknown}" "${BASH_LINENO[$((i-1))]:-0}" "${FUNCNAME[$i]:-main}"
  done
}
runtime_stage_begin() {
  DOTFILES_STAGE_ID="$1"; DOTFILES_STAGE_PARENT="${2-setup}"; DOTFILES_STAGE_PREREQUISITES="${3:-}"; DOTFILES_STAGE_STARTED=$SECONDS
  runtime_event stage_start "$DOTFILES_STAGE_ID" "$DOTFILES_STAGE_PARENT" "" 0 "" "$DOTFILES_STAGE_PREREQUISITES"
}
runtime_stage_end() {
  local stack=""
  [[ "$2" == failed ]] && stack="$(runtime_stack)"
  printf '%s\t%s\t%s\t\t\n' "$2" "$1" "${4:-exit status ${3:-0}}" | runtime_sanitize >> "$DOTFILES_SETUP_SUMMARY_FILE"
  runtime_event stage_end "$1" "${DOTFILES_STAGE_PARENT-setup}" "$2" "${3:-0}" "${4:-}" "${DOTFILES_STAGE_PREREQUISITES:-}" "$((SECONDS-${DOTFILES_STAGE_STARTED:-SECONDS}))" "$stack"
}
runtime_record() {
  local kind="$1" name="$2" reason="${3:-}" log_file="${4:-}" fix="${5:-}" outcome="$1" status=0 stack=""
  case "$kind" in critical|recoverable|failed) outcome=failed; status=1; stack="$(runtime_stack)";; blocked) status=1;; cancelled) status="${DOTFILES_RUNTIME_CANCELLED:-130}";; esac
  printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$name" "$reason" "$log_file" "$fix" | runtime_sanitize >> "$DOTFILES_SETUP_SUMMARY_FILE"
  runtime_event result "${DOTFILES_STAGE_ID:-$(runtime_sanitize_name "$name")}" "${DOTFILES_STAGE_PARENT:-setup}" "$outcome" "$status" "$name: $reason" "${DOTFILES_STAGE_PREREQUISITES:-}" 0 "$stack"
}
runtime_record_completed() { runtime_record completed "$1" "${2:-completed}"; }
runtime_record_deferred() { runtime_record deferred "$1" "${2:-deferred}" "" "${3:-}"; }
runtime_record_planned() { runtime_record planned "$1" "${2:-simulated; no provisioning executed}"; }
runtime_record_blocked() { runtime_record blocked "$1" "${2:-prerequisite unavailable}"; }
runtime_record_failure() { runtime_record "$1" "$2" "$3" "${4:-}" "${5:-}"; }
runtime_acquire_lock() {
  local lock_name="$1" lock_dir="${DOTFILES_RUNTIME_LOCK_ROOT}/$1.lock" pid=""
  mkdir -p "$DOTFILES_RUNTIME_LOCK_ROOT"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    [[ -f "$lock_dir/pid" ]] && read -r pid < "$lock_dir/pid"
    if [[ "$pid" =~ ^[0-9]+$ ]] && ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$lock_dir/pid"; rmdir "$lock_dir" 2>/dev/null || return 1
      mkdir "$lock_dir" 2>/dev/null || return 1
    else
      runtime_record_failure critical "${2:-$1}" "another process holds $lock_dir"
      return 1
    fi
  fi
  printf '%s\n' "${DOTFILES_RUNTIME_PID:-$$}" > "$lock_dir/pid"
  DOTFILES_RUNTIME_HELD_LOCKS+=("$lock_dir")
}
runtime_release_lock() {
  local target="${DOTFILES_RUNTIME_LOCK_ROOT}/$1.lock" held next=()
  for held in "${DOTFILES_RUNTIME_HELD_LOCKS[@]:-}"; do
    if [[ "$held" == "$target" ]]; then rm -f "$held/pid"; rmdir "$held" 2>/dev/null || true
    elif [[ -n "$held" ]]; then next+=("$held"); fi
  done
  DOTFILES_RUNTIME_HELD_LOCKS=("${next[@]:-}")
  return 0
}
runtime_release_locks() {
  local held
  for held in "${DOTFILES_RUNTIME_HELD_LOCKS[@]:-}"; do
    [[ -n "$held" ]] || continue
    rm -f "$held/pid"; rmdir "$held" 2>/dev/null || true
  done
  DOTFILES_RUNTIME_HELD_LOCKS=()
}
runtime_acquire_global_lock() {
  [[ "${DOTFILES_SETUP_GLOBAL_LOCK_HELD:-0}" == 1 ]] && return 0
  runtime_acquire_lock setup-bootstrap "setup lock" || return 1
  export DOTFILES_SETUP_GLOBAL_LOCK_HELD=1
  DOTFILES_RUNTIME_OWNS_GLOBAL_LOCK=1
}
# Snapshot and stop the complete descendant tree before terminating it, so children
# cannot escape by being reparented while their parents are being killed.
runtime_descendants() {
  ps -axo pid=,ppid= | awk -v root="$1" '
    { parent[$1]=$2 }
    END { for (pid in parent) { current=pid; for (n=0; n<100 && current in parent; n++) { if (parent[current] == root) { print pid; break }; current=parent[current] } } }'
}
runtime_cleanup_jobs() {
  local owned pid attempts owner="${DOTFILES_RUNTIME_PID:-$$}"
  if ! owned="$(runtime_descendants "$owner")"; then
    runtime_warn "Cannot enumerate owned descendants; process inspection is required for complete cancellation."
    owned="${DOTFILES_JOB_PIDS[*]:-}"
  fi
  for pid in $owned; do kill -STOP "$pid" 2>/dev/null || true; done
  for pid in $owned; do kill -TERM "$pid" 2>/dev/null || true; kill -CONT "$pid" 2>/dev/null || true; done
  for attempts in 1 2 3 4 5; do
    local alive=0
    for pid in $owned; do kill -0 "$pid" 2>/dev/null && alive=1; done
    [[ "$alive" == 0 ]] && break
    sleep 0.2
  done
  for pid in $owned; do kill -KILL "$pid" 2>/dev/null || true; done
  for pid in "${DOTFILES_JOB_PIDS[@]:-}"; do [[ -n "$pid" ]] && wait "$pid" 2>/dev/null || true; done
  local lock owner_pid
  for lock in "$DOTFILES_RUNTIME_LOCK_ROOT"/*.lock; do
    [[ -f "$lock/pid" ]] || continue
    read -r owner_pid < "$lock/pid"
    for pid in $owned; do
      if [[ "$owner_pid" == "$pid" ]]; then rm -f "$lock/pid"; rmdir "$lock" 2>/dev/null || true; fi
    done
  done
  DOTFILES_JOB_PIDS=()
  return 0
}
runtime_signal() {
  local signal="$1" status="$2"
  trap '' INT TERM
  DOTFILES_RUNTIME_CANCELLED="$status"
  runtime_event cancellation "${DOTFILES_STAGE_ID:-setup}" setup cancelled "$status" "received SIG$signal"
  runtime_record cancelled "Setup" "received SIG$signal"
  runtime_cleanup
  exit "$status"
}
runtime_cleanup() {
  [[ "${DOTFILES_RUNTIME_CLEANED:-0}" == 1 ]] && return 0
  DOTFILES_RUNTIME_CLEANED=1
  runtime_cleanup_jobs
  runtime_release_locks
  runtime_merge_trace
}
runtime_on_exit() {
  local status="$1"
  if [[ "$status" != 0 && "$status" != 20 && "${DOTFILES_RUNTIME_CANCELLED:-0}" == 0 ]]; then
    runtime_event failure "${DOTFILES_STAGE_ID:-setup}" setup failed "$status" "process exited" "" 0 "$(runtime_stack)"
  fi
  runtime_cleanup
}
runtime_run_job() {
  local name="$1" severity="$2" fix="$3" index="${#DOTFILES_JOB_PIDS[@]}" log_file id
  shift 3
  [[ "${DOTFILES_RUNTIME_CANCELLED:-0}" == 0 ]] || return "$DOTFILES_RUNTIME_CANCELLED"
  id="${DOTFILES_NEXT_STAGE_ID:-$(runtime_sanitize_name "$name")-${DOTFILES_RUNTIME_STREAM_ID}-$index}"
  local parent="${DOTFILES_NEXT_PARENT_ID:-${DOTFILES_STAGE_ID:-setup}}" prerequisites="${DOTFILES_NEXT_PREREQUISITES:-${DOTFILES_STAGE_PREREQUISITES:-}}"
  log_file="$DOTFILES_SETUP_LOG_DIR/$id.log"
  runtime_log "Starting $name (elapsed 0s; log: $log_file)"
  runtime_event stage_start "$id" "$parent" "" 0 "$name" "$prerequisites"
  (
    DOTFILES_RUNTIME_HELD_LOCKS=(); DOTFILES_JOB_PIDS=(); DOTFILES_RUNTIME_CLEANED=0
    DOTFILES_RUNTIME_STREAM_ID="$RANDOM.$RANDOM"
    export DOTFILES_STAGE_ID="$id" DOTFILES_STAGE_PARENT="$parent" DOTFILES_STAGE_PREREQUISITES="$prerequisites"
    DOTFILES_RUNTIME_PID="$(sh -c 'echo "$PPID"')"
    trap 'runtime_signal INT 130' INT; trap 'runtime_signal TERM 143' TERM
    trap 'runtime_on_exit $?' EXIT
    set -o pipefail
    "$@" 2>&1 | runtime_sanitize | runtime_stream_output "$log_file" "$name"
  ) &
  DOTFILES_JOB_PIDS+=("$!"); DOTFILES_JOB_NAMES+=("$name"); DOTFILES_JOB_SEVERITIES+=("$severity"); DOTFILES_JOB_FIXES+=("$fix"); DOTFILES_JOB_LOGS+=("$log_file"); DOTFILES_JOB_STARTS+=("$SECONDS"); DOTFILES_JOB_IDS+=("$id"); DOTFILES_JOB_PARENTS+=("$parent"); DOTFILES_JOB_PREREQS+=("$prerequisites")
  if [[ "${DOTFILES_SETUP_SERIAL:-0}" == 1 ]]; then runtime_wait_job "$index" || DOTFILES_JOB_FAILED=1; fi
  return 0
}
runtime_wait_job() {
  local i="$1" status=0 pid="${DOTFILES_JOB_PIDS[$1]}" elapsed=0 next="${DOTFILES_PROGRESS_INTERVAL:-15}" size=0 previous_size=0
  [[ -n "$pid" ]] || return 0
  while kill -0 "$pid" 2>/dev/null; do
    elapsed=$((SECONDS-${DOTFILES_JOB_STARTS[$i]}))
    if (( elapsed >= next )); then
      size="$(wc -c < "${DOTFILES_JOB_LOGS[$i]}" 2>/dev/null || printf 0)"
      if [[ "$size" -eq "$previous_size" ]]; then
        runtime_log "${DOTFILES_JOB_NAMES[$i]} still running (${elapsed}s; no new output; log: ${DOTFILES_JOB_LOGS[$i]})"
      fi
      previous_size="$size"
      next=$((elapsed+${DOTFILES_PROGRESS_INTERVAL:-15}))
    fi
    sleep 0.2
  done
  wait "$pid" || status=$?
  DOTFILES_JOB_PIDS[$i]=""
  local previous_id="${DOTFILES_STAGE_ID:-setup}" previous_parent="${DOTFILES_STAGE_PARENT-setup}" previous_prereqs="${DOTFILES_STAGE_PREREQUISITES:-}"
  DOTFILES_STAGE_ID="${DOTFILES_JOB_IDS[$i]}"
  DOTFILES_STAGE_PARENT="${DOTFILES_JOB_PARENTS[$i]}"
  DOTFILES_STAGE_PREREQUISITES="${DOTFILES_JOB_PREREQS[$i]}"
  if [[ "$status" == 20 ]]; then runtime_record_deferred "${DOTFILES_JOB_NAMES[$i]}"
  elif [[ "$status" == 0 ]]; then runtime_record_completed "${DOTFILES_JOB_NAMES[$i]}"
  else runtime_record_failure "${DOTFILES_JOB_SEVERITIES[$i]}" "${DOTFILES_JOB_NAMES[$i]}" "exited with status $status" "${DOTFILES_JOB_LOGS[$i]}" "${DOTFILES_JOB_FIXES[$i]}"; fi
  local outcome=completed stack=""
  if [[ "$status" == 20 ]]; then outcome=deferred
  elif [[ "$status" != 0 ]]; then outcome=failed; stack="$(runtime_stack)"; fi
  runtime_log "${DOTFILES_JOB_NAMES[$i]}: $outcome ($((SECONDS-${DOTFILES_JOB_STARTS[$i]}))s; exit $status)"
  runtime_event stage_end "${DOTFILES_JOB_IDS[$i]}" "${DOTFILES_JOB_PARENTS[$i]}" "$outcome" "$status" "${DOTFILES_JOB_NAMES[$i]}" "${DOTFILES_JOB_PREREQS[$i]}" "$((SECONDS-${DOTFILES_JOB_STARTS[$i]}))" "$stack"
  runtime_merge_trace
  DOTFILES_STAGE_ID="$previous_id"; DOTFILES_STAGE_PARENT="$previous_parent"; DOTFILES_STAGE_PREREQUISITES="$previous_prereqs"
  return "$status"
}
runtime_wait_jobs() {
  local i failed="$DOTFILES_JOB_FAILED"
  for ((i=0; i<${#DOTFILES_JOB_PIDS[@]}; i++)); do runtime_wait_job "$i" || failed=1; done
  DOTFILES_JOB_PIDS=(); DOTFILES_JOB_NAMES=(); DOTFILES_JOB_SEVERITIES=(); DOTFILES_JOB_FIXES=(); DOTFILES_JOB_LOGS=(); DOTFILES_JOB_STARTS=(); DOTFILES_JOB_IDS=(); DOTFILES_JOB_PARENTS=(); DOTFILES_JOB_PREREQS=(); DOTFILES_JOB_FAILED=0
  return "$failed"
}
runtime_run_step() { DOTFILES_SETUP_SERIAL=1 runtime_run_job "$@"; }
# Authentication output is intentionally not captured: prompts stay on the TTY.
runtime_run_foreground() {
  local name="$1"
  shift
  runtime_execute_stage "$(runtime_sanitize_name "$name")" "${DOTFILES_STAGE_ID:-setup}" "" sensitive "$@"
}
runtime_print_section() {
  local kind="$1" title="$2" found=0 record_kind name reason log_file fix
  printf '\n%s\n' "$title"
  while IFS=$'\t' read -r record_kind name reason log_file fix || [[ -n "${record_kind:-}" ]]; do
    [[ "$record_kind" == "$kind" ]] || continue
    found=1; printf -- '- %s: %s\n' "$name" "$reason"
  done < "$DOTFILES_SETUP_SUMMARY_FILE"
  [[ "$found" == 1 ]] || printf -- '- none\n'
}
runtime_print_summary() {
  runtime_merge_trace
  printf '\nSetup result summary — diagnostics: %s\n' "$DOTFILES_SETUP_LOG_DIR"
  runtime_print_section completed Completed
  runtime_print_section planned Planned
  runtime_print_section recoverable Failed
  runtime_print_section failed Failed
  runtime_print_section blocked Blocked
  runtime_print_section deferred Deferred/manual
  runtime_print_section cancelled Cancelled
  runtime_print_section critical 'Critical failure'
}
runtime_has_failures() { LC_ALL=C grep -Eq '^(critical|recoverable|failed|blocked|cancelled)[[:space:]]' "$DOTFILES_SETUP_SUMMARY_FILE"; }
runtime_exit_status() { if runtime_has_failures; then return 1; fi; return 0; }

runtime_owner_is_ancestor() {
  local owner="$1" current="${DOTFILES_RUNTIME_PID:-$$}"
  [[ "$owner" == "$current" ]] && return 0
  ps -axo pid=,ppid= | awk -v owner="$owner" -v current="$current" '
    { parent[$1]=$2 }
    END { for (n=0; n<100 && current in parent; n++) { current=parent[current]; if (current == owner) exit 0 }; exit 1 }'
}
# Resource locks are inherited only by descendants of the current owner. This
# permits a locked helper to call another locked helper without deadlocking.
runtime_with_lock() {
  local resource="$1" variable value status=0 started=$SECONDS
  shift
  [[ "$resource" =~ ^[A-Za-z0-9_-]+$ ]] || return 2
  variable="DOTFILES_RESOURCE_$(printf '%s' "$resource" | tr '[:lower:]-' '[:upper:]_')_OWNER"
  eval 'value=${'"$variable"':-}'
  if [[ "$value" =~ ^[0-9]+$ ]] && kill -0 "$value" 2>/dev/null && runtime_owner_is_ancestor "$value"; then "$@"; return $?; fi
  local dir="$DOTFILES_RUNTIME_LOCK_ROOT/$resource.lock"
  mkdir -p "$DOTFILES_RUNTIME_LOCK_ROOT"
  until mkdir "$dir" 2>/dev/null; do
    local held_pid=""
    [[ -f "$dir/pid" ]] && read -r held_pid < "$dir/pid"
    if [[ "$held_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$held_pid" 2>/dev/null; then
      rm -f "$dir/pid"; rmdir "$dir" 2>/dev/null || true
      continue
    fi
    [[ "$((SECONDS-started))" -lt "${DOTFILES_LOCK_TIMEOUT:-600}" ]] || { runtime_record_failure recoverable "$resource lock" "timed out waiting for package writer"; return 1; }
    sleep 0.2
  done
  printf '%s\n' "${DOTFILES_RUNTIME_PID:-$$}" > "$dir/pid"
  DOTFILES_RUNTIME_HELD_LOCKS+=("$dir")
  export "$variable=${DOTFILES_RUNTIME_PID:-$$}"
  "$@" || status=$?
  unset "$variable"
  runtime_release_lock "$resource"
  return "$status"
}
runtime_execute_stage() {
  local id="$1" parent="$2" prerequisites="$3" capture="$4" status=0 previous="${DOTFILES_STAGE_ID:-setup}"
  shift 4
  runtime_stage_begin "$id" "$parent" "$prerequisites"
  if [[ "$capture" == probe ]]; then runtime_event probe "$id" "$parent" "" 0 "executing external read-only checks" "$prerequisites"; fi
  if [[ "$capture" == local ]]; then
    "$@" || status=$?
  elif [[ "$capture" == sensitive ]]; then
    runtime_log "Running $id (elapsed 0s; diagnostics: $DOTFILES_SETUP_LOG_DIR; sensitive output omitted)"
    # Explicit stdin preserves interactive prompts; wait is interruptible even
    # when a foreground external command would defer the shell's signal trap.
    (
      DOTFILES_RUNTIME_PID="$(sh -c 'echo "$PPID"')"
      DOTFILES_RUNTIME_HELD_LOCKS=(); DOTFILES_JOB_PIDS=(); DOTFILES_RUNTIME_CLEANED=0
      DOTFILES_RUNTIME_STREAM_ID="$RANDOM.$RANDOM"
      export DOTFILES_STAGE_ID DOTFILES_STAGE_PARENT DOTFILES_STAGE_PREREQUISITES
      trap 'runtime_signal INT 130' INT; trap 'runtime_signal TERM 143' TERM
      trap 'runtime_on_exit $?' EXIT
      "$@"
    ) <&0 &
    local foreground_pid=$!
    wait "$foreground_pid" || status=$?
    runtime_log "$id finished (exit $status)"
  else
    local index="${#DOTFILES_JOB_PIDS[@]}"
    DOTFILES_SETUP_SERIAL=0 runtime_run_job "$id" recoverable "Inspect stage diagnostics and rerun setup." "$@"
    runtime_wait_job "$index" || status=$?
  fi
  if [[ "$status" == 20 ]]; then runtime_stage_end "$id" deferred 20
  elif [[ "$status" == 0 ]]; then runtime_stage_end "$id" completed 0
  else runtime_stage_end "$id" failed "$status"; fi
  DOTFILES_STAGE_ID="$previous"
  return "$status"
}
