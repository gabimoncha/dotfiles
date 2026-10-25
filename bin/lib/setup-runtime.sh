#!/usr/bin/env bash
# Logs, result records, locks, and background jobs for bin/setup and its
# helpers. Each run writes one folder in .local/setup-runs/: setup.log holds the
# sanitized output, and summary.txt holds one result line for each step.
# Bash 3.2 compatible. Never enable xtrace here: credentials may be in memory.
# Apply opt-outs before installers and health probes can run managed tools.
if [[ -n "${repo_root:-}" && -r "$repo_root/configs/zsh/telemetry.sh" ]]; then
  . "$repo_root/configs/zsh/telemetry.sh"
fi
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
# Shows each line with the job name and appends it to the run log.
runtime_stream_output() {
  local line
  # Shell printf writes each line immediately, including an unterminated tail.
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '[%s] %s\n' "$2" "$line" >&3
    printf '[%s] %s\n' "$2" "$line"
  done 3>> "$1"
}
runtime_log() { printf '==> %s\n' "$1"; }
runtime_warn() { printf '!! %s\n' "$1" >&2; }
runtime_prune_logs() {
  /usr/bin/ruby -rfileutils - "$1" <<'RUBY'
root = File.expand_path(ARGV.fetch(0))
File.open(File.join(root, '.retention.lock'), File::RDWR | File::CREAT | File::NOFOLLOW, 0600) do |lock|
  lock.flock(File::LOCK_EX)
  runs = Dir.children(root).each_with_object([]) do |name, entries|
    next unless name.match?(/\A\d{8}T\d{6}Z-[A-Za-z0-9]{6}\z/)
    path = File.join(root, name)
    stat = File.lstat(path)
    next unless stat.directory? && stat.uid == Process.uid
    summary = File.join(path, 'summary.txt')
    next unless File.file?(summary) && !File.symlink?(summary)
    # Linux Ruby has no birthtime. Run names start with their UTC start time,
    # which sorts in the same order.
    created = begin
      stat.birthtime.utc.strftime('%Y%m%dT%H%M%SZ')
    rescue NotImplementedError
      name[0, 16]
    end
    entries << [path, created]
  end
  runs.sort_by { |path, created| [created, path] }.reverse.drop(3).each do |path, _|
    owner = File.join(path, '.owner-pid')
    if File.exist?(owner) || File.symlink?(owner)
      next if File.symlink?(owner) || !File.file?(owner)
      begin
        pid = File.read(owner).strip
      rescue Errno::ENOENT
        next
      end
      next unless pid.match?(/\A[1-9]\d*\z/)
      begin
        Process.kill(0, pid.to_i)
        next
      rescue Errno::ESRCH
        # A killed run has no exit cleanup. Its logs can still expire.
      rescue Errno::EPERM
        next
      end
    end
    FileUtils.remove_entry_secure(path)
  end
end
RUBY
}
runtime_init() {
  [[ "${DOTFILES_RUNTIME_INITIALIZED:-0}" == 1 ]] && return 0
  DOTFILES_RUNTIME_INITIALIZED=1
  DOTFILES_RUNTIME_PID="$(exec sh -c 'echo "$PPID"')"
  DOTFILES_RUNTIME_SCRIPT="${1:-setup}"
  DOTFILES_RUN_MODE="${2:-${DOTFILES_RUN_MODE:-normal}}"
  DOTFILES_RUNTIME_OWNS_LOG_DIR=0
  DOTFILES_RUNTIME_CANCELLED=0
  DOTFILES_RUNTIME_CLEANED=0
  DOTFILES_RUNTIME_LOCK_ROOT="${DOTFILES_RUNTIME_LOCK_ROOT:-${TMPDIR:-/tmp}/dotfiles-locks-${UID}}"
  DOTFILES_RUNTIME_HELD_LOCKS=()
  DOTFILES_JOB_PIDS=(); DOTFILES_JOB_NAMES=(); DOTFILES_JOB_SEVERITIES=(); DOTFILES_JOB_FIXES=(); DOTFILES_JOB_STARTS=(); DOTFILES_JOB_FAILED=0
  umask 077
  # A helper that setup runs writes into the folder of that setup run.
  if [[ -z "${DOTFILES_SETUP_LOG_DIR:-}" ]]; then
    local root="${DOTFILES_SETUP_RUN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.local/setup-runs}"
    mkdir -p "$root"
    DOTFILES_SETUP_LOG_DIR="$(mktemp -d "$root/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
    printf '%s\n' "$DOTFILES_RUNTIME_PID" > "$DOTFILES_SETUP_LOG_DIR/.owner-pid"
    DOTFILES_RUNTIME_OWNS_LOG_DIR=1
    DOTFILES_SETUP_SUMMARY_FILE="$DOTFILES_SETUP_LOG_DIR/summary.txt"
    DOTFILES_SETUP_LOG="$DOTFILES_SETUP_LOG_DIR/setup.log"
  fi
  chmod 700 "$DOTFILES_SETUP_LOG_DIR"
  DOTFILES_SETUP_SUMMARY_FILE="${DOTFILES_SETUP_SUMMARY_FILE:-$DOTFILES_SETUP_LOG_DIR/summary.txt}"
  DOTFILES_SETUP_LOG="${DOTFILES_SETUP_LOG:-$DOTFILES_SETUP_LOG_DIR/setup.log}"
  touch "$DOTFILES_SETUP_SUMMARY_FILE" "$DOTFILES_SETUP_LOG"
  chmod 600 "$DOTFILES_SETUP_SUMMARY_FILE" "$DOTFILES_SETUP_LOG"
  export DOTFILES_SETUP_LOG_DIR DOTFILES_SETUP_SUMMARY_FILE DOTFILES_SETUP_LOG DOTFILES_RUN_MODE
  runtime_log "Diagnostic logs: $DOTFILES_SETUP_LOG_DIR"
  if [[ "$DOTFILES_RUNTIME_OWNS_LOG_DIR" == 1 ]]; then
    local metadata_root commit dirty
    metadata_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    commit="$(git -C "$metadata_root" rev-parse HEAD 2>/dev/null || printf unknown)"
    dirty="$( (git -C "$metadata_root" status --porcelain --untracked-files=normal 2>/dev/null || true) | wc -l | tr -d ' ')"
    printf '%s started %s in %s mode, commit %s, %s changed files\n' \
      "$DOTFILES_RUNTIME_SCRIPT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DOTFILES_RUN_MODE" "$commit" "$dirty" >> "$DOTFILES_SETUP_LOG"
  fi
  trap 'runtime_signal INT 130' INT
  trap 'runtime_signal TERM 143' TERM
  trap 'runtime_on_exit $?' EXIT
  if [[ "$DOTFILES_RUNTIME_OWNS_LOG_DIR" == 1 ]]; then
    runtime_prune_logs "$(dirname "$DOTFILES_SETUP_LOG_DIR")" || runtime_warn "Could not remove old setup logs."
  fi
}
# Usage: runtime_record KIND NAME [REASON] [LOG] [FIX]. KIND is completed,
# planned, deferred, blocked, recoverable, failed, critical, or cancelled.
runtime_record() {
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "${3:-}" "${4:-}" "${5:-}" | runtime_sanitize >> "$DOTFILES_SETUP_SUMMARY_FILE"
}
runtime_record_completed() { runtime_record completed "$1" "${2:-completed}"; }
runtime_record_deferred() { runtime_record deferred "$1" "${2:-deferred}" "" "${3:-}"; }
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
    for pid in "$owner" $owned; do
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
  # The parent records the cancellation once. A job only stops its own children.
  [[ "${DOTFILES_RUNTIME_CHILD:-0}" == 1 ]] || runtime_record cancelled "Setup" "received SIG$signal"
  runtime_cleanup
  exit "$status"
}
runtime_cleanup() {
  [[ "${DOTFILES_RUNTIME_CLEANED:-0}" == 1 ]] && return 0
  DOTFILES_RUNTIME_CLEANED=1
  runtime_cleanup_jobs
  runtime_release_locks
}
runtime_on_exit() {
  local status="${1:-0}"
  # A helper that fails without a record leaves one, so its saved logs show the
  # failure. Setup records each step, and a job reports to its parent.
  if [[ "$status" != 0 && "$status" != 20 && "${DOTFILES_RUNTIME_CANCELLED:-0}" == 0 &&
    "${DOTFILES_RUNTIME_OWNS_LOG_DIR:-0}" == 1 && "${DOTFILES_RUNTIME_CHILD:-0}" != 1 &&
    "${DOTFILES_RUNTIME_SCRIPT:-setup}" != setup ]] && ! runtime_has_failures; then
    runtime_record failed "$DOTFILES_RUNTIME_SCRIPT" "exited with status $status"
  fi
  runtime_cleanup
  if [[ "${DOTFILES_RUNTIME_OWNS_LOG_DIR:-0}" == 1 && -f "$DOTFILES_SETUP_LOG_DIR/.owner-pid" ]]; then
    local owner
    read -r owner < "$DOTFILES_SETUP_LOG_DIR/.owner-pid"
    if [[ "$owner" == "$(exec sh -c 'echo "$PPID"')" ]]; then
      rm -- "$DOTFILES_SETUP_LOG_DIR/.owner-pid"
    fi
  fi
}
# Usage: runtime_run_job NAME SEVERITY FIX COMMAND... Starts COMMAND in the
# background. Its output is shown and added to the run log. A positive
# DOTFILES_JOB_IDLE_TIMEOUT_SECONDS stops a job that prints nothing for that long.
runtime_run_job() {
  local name="$1" severity="$2" fix="$3" log_file="$DOTFILES_SETUP_LOG"
  shift 3
  [[ "${DOTFILES_RUNTIME_CANCELLED:-0}" == 0 ]] || return "$DOTFILES_RUNTIME_CANCELLED"
  runtime_log "Starting $name (log: $log_file)"
  (
    DOTFILES_RUNTIME_HELD_LOCKS=(); DOTFILES_JOB_PIDS=(); DOTFILES_RUNTIME_CLEANED=0; export DOTFILES_RUNTIME_CHILD=1
    DOTFILES_RUNTIME_PID="$(exec sh -c 'echo "$PPID"')"
    trap 'runtime_signal INT 130' INT; trap 'runtime_signal TERM 143' TERM
    trap 'runtime_on_exit $?' EXIT
    set -o pipefail
    if [[ "${DOTFILES_JOB_IDLE_TIMEOUT_SECONDS:-0}" == 0 ]]; then
      "$@" 2>&1 | runtime_sanitize | runtime_stream_output "$log_file" "$name"
    else
      # Each job watches its own output, even while the parent waits for
      # another job. Other jobs write to the shared log, so the job counts its
      # output in a file of its own.
      local activity pipeline_pid last_output=$SECONDS previous_size=0 size status=0
      activity="$(mktemp "$DOTFILES_SETUP_LOG_DIR/.activity.XXXXXX")"
      "$@" 2>&1 | runtime_sanitize | tee -a "$activity" | runtime_stream_output "$log_file" "$name" &
      pipeline_pid=$!
      while kill -0 "$pipeline_pid" 2>/dev/null; do
        size="$(wc -c < "$activity")"
        if [[ "$size" -ne "$previous_size" ]]; then
          last_output=$SECONDS
          previous_size="$size"
        fi
        if (( SECONDS-last_output >= DOTFILES_JOB_IDLE_TIMEOUT_SECONDS )); then
          runtime_warn "$name timed out after ${DOTFILES_JOB_IDLE_TIMEOUT_SECONDS}s without output; stopping update (log: $log_file)"
          rm -f "$activity"
          runtime_cleanup_jobs
          exit 124
        fi
        sleep 0.2
      done
      wait "$pipeline_pid" || status=$?
      rm -f "$activity"
      exit "$status"
    fi
  ) &
  DOTFILES_JOB_PIDS+=("$!"); DOTFILES_JOB_NAMES+=("$name"); DOTFILES_JOB_SEVERITIES+=("$severity"); DOTFILES_JOB_FIXES+=("$fix"); DOTFILES_JOB_STARTS+=("$SECONDS")
  return 0
}
# Waits for job INDEX and records its result.
runtime_wait_job() {
  local i="$1" status=0 pid="${DOTFILES_JOB_PIDS[$1]}" elapsed=0 next="${DOTFILES_PROGRESS_INTERVAL:-15}" size=0 previous_size=0
  [[ -n "$pid" ]] || return 0
  while kill -0 "$pid" 2>/dev/null; do
    elapsed=$((SECONDS-${DOTFILES_JOB_STARTS[$i]}))
    if (( elapsed >= next )); then
      size="$(wc -c < "$DOTFILES_SETUP_LOG" 2>/dev/null || printf 0)"
      if [[ "$size" -eq "$previous_size" ]]; then
        runtime_log "${DOTFILES_JOB_NAMES[$i]} still running (${elapsed}s; no new output; log: $DOTFILES_SETUP_LOG)"
      fi
      previous_size="$size"
      next=$((elapsed+${DOTFILES_PROGRESS_INTERVAL:-15}))
    fi
    sleep 0.2
  done
  wait "$pid" || status=$?
  DOTFILES_JOB_PIDS[$i]=""
  local outcome=completed
  if [[ "$status" == 20 ]]; then
    outcome=deferred
    runtime_record_deferred "${DOTFILES_JOB_NAMES[$i]}"
  elif [[ "$status" == 0 ]]; then
    runtime_record_completed "${DOTFILES_JOB_NAMES[$i]}"
  else
    outcome=failed
    local reason="exited with status $status"
    if [[ "$status" == 124 && "${DOTFILES_JOB_IDLE_TIMEOUT_SECONDS:-0}" != 0 ]]; then
      reason="timed out after ${DOTFILES_JOB_IDLE_TIMEOUT_SECONDS}s without output; update stopped"
    fi
    runtime_record_failure "${DOTFILES_JOB_SEVERITIES[$i]}" "${DOTFILES_JOB_NAMES[$i]}" "$reason" "$DOTFILES_SETUP_LOG" "${DOTFILES_JOB_FIXES[$i]}"
  fi
  runtime_log "${DOTFILES_JOB_NAMES[$i]}: $outcome ($((SECONDS-${DOTFILES_JOB_STARTS[$i]}))s; exit $status)"
  return "$status"
}
runtime_wait_jobs() {
  local i failed="$DOTFILES_JOB_FAILED"
  for ((i=0; i<${#DOTFILES_JOB_PIDS[@]}; i++)); do runtime_wait_job "$i" || failed=1; done
  DOTFILES_JOB_PIDS=(); DOTFILES_JOB_NAMES=(); DOTFILES_JOB_SEVERITIES=(); DOTFILES_JOB_FIXES=(); DOTFILES_JOB_STARTS=(); DOTFILES_JOB_FAILED=0
  return "$failed"
}
# Usage: runtime_execute_stage ID MODE COMMAND... and records the result.
# MODE probe or capture shows the output and adds it to the run log. MODE local
# runs in this shell, so the command can change its variables. MODE sensitive
# keeps the terminal for prompts and logs no output.
runtime_execute_stage() {
  local id="$1" mode="$2" status=0 index fix="Repair the cause, then rerun ${DOTFILES_SETUP_RERUN:-./bin/setup}."
  shift 2
  case "$mode" in
    probe|capture)
      index="${#DOTFILES_JOB_PIDS[@]}"
      runtime_run_job "$id" recoverable "$fix" "$@"
      # runtime_wait_job records the result.
      runtime_wait_job "$index" || status=$?
      return "$status"
      ;;
    local) "$@" || status=$? ;;
    sensitive)
      runtime_log "Running $id (output is not logged)"
      # Explicit stdin keeps prompts working. wait returns on a signal, while a
      # foreground command would delay the signal trap until it ends.
      (
        DOTFILES_RUNTIME_PID="$(exec sh -c 'echo "$PPID"')"
        DOTFILES_RUNTIME_HELD_LOCKS=(); DOTFILES_JOB_PIDS=(); DOTFILES_RUNTIME_CLEANED=0; export DOTFILES_RUNTIME_CHILD=1
        trap 'runtime_signal INT 130' INT; trap 'runtime_signal TERM 143' TERM
        trap 'runtime_on_exit $?' EXIT
        "$@"
      ) <&0 &
      wait "$!" || status=$?
      runtime_log "$id finished (exit $status)"
      ;;
    *) runtime_warn "Unknown step mode $mode for $id"; return 2 ;;
  esac
  if [[ "$status" == 20 ]]; then runtime_record_deferred "$id"
  elif [[ "$status" == 0 ]]; then runtime_record_completed "$id"
  else runtime_record_failure recoverable "$id" "exited with status $status" "" "$fix"; fi
  return "$status"
}
# Usage: runtime_print_section "KIND..." TITLE
runtime_print_section() {
  local kinds=" $1 " title="$2" found=0 record_kind name reason log_file fix
  printf '\n%s\n' "$title"
  while IFS=$'\t' read -r record_kind name reason log_file fix || [[ -n "${record_kind:-}" ]]; do
    [[ "$kinds" == *" ${record_kind:-none} "* ]] || continue
    found=1; printf -- '- %s: %s\n' "$name" "$reason"
  done < "$DOTFILES_SETUP_SUMMARY_FILE"
  [[ "$found" == 1 ]] || printf -- '- none\n'
}
runtime_print_summary() {
  printf '\nSetup result summary. Logs: %s\n' "$DOTFILES_SETUP_LOG_DIR"
  runtime_print_section completed Completed
  runtime_print_section planned Planned
  runtime_print_section "recoverable failed" Failed
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
