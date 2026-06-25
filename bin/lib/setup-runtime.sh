#!/usr/bin/env bash

runtime_init() {
  local script_name="${1:-dotfiles}"

  if [[ "${DOTFILES_RUNTIME_INITIALIZED:-0}" -eq 1 ]]; then
    return 0
  fi

  DOTFILES_RUNTIME_INITIALIZED=1
  DOTFILES_RUNTIME_SCRIPT="$script_name"
  DOTFILES_RUNTIME_OWNS_SUMMARY=0
  DOTFILES_RUNTIME_OWNS_LOG_DIR=0
  DOTFILES_RUNTIME_LOCK_ROOT="${TMPDIR:-/tmp}/dotfiles-locks"
  DOTFILES_RUNTIME_HELD_LOCKS=()
  DOTFILES_JOB_PIDS=()
  DOTFILES_JOB_NAMES=()
  DOTFILES_JOB_SEVERITIES=()
  DOTFILES_JOB_FIXES=()
  DOTFILES_JOB_LOGS=()
  DOTFILES_JOB_FAILED=0

  if [[ -z "${DOTFILES_SETUP_SUMMARY_FILE:-}" ]]; then
    DOTFILES_SETUP_SUMMARY_FILE="$(mktemp "${TMPDIR:-/tmp}/dotfiles-setup-summary.XXXXXX")"
    DOTFILES_RUNTIME_OWNS_SUMMARY=1
    export DOTFILES_SETUP_SUMMARY_FILE
  else
    touch "$DOTFILES_SETUP_SUMMARY_FILE"
  fi

  if [[ -z "${DOTFILES_SETUP_LOG_DIR:-}" ]]; then
    DOTFILES_SETUP_LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup-logs.XXXXXX")"
    DOTFILES_RUNTIME_OWNS_LOG_DIR=1
    export DOTFILES_SETUP_LOG_DIR
  else
    mkdir -p "$DOTFILES_SETUP_LOG_DIR"
  fi
}

runtime_sanitize_name() {
  printf '%s' "$1" | tr -c '[:alnum:]._' '-'
}

runtime_log() {
  printf '==> %s\n' "$1"
}

runtime_warn() {
  printf '!! %s\n' "$1" >&2
}

runtime_record() {
  local kind="$1"
  local name="$2"
  local reason="${3:-}"
  local log_file="${4:-}"
  local fix="${5:-}"

  printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$name" "$reason" "$log_file" "$fix" >> "$DOTFILES_SETUP_SUMMARY_FILE"
}

runtime_record_completed() {
  runtime_record completed "$1" "${2:-completed}" "" ""
}

runtime_record_deferred() {
  runtime_record deferred "$1" "${2:-deferred}" "" "${3:-}"
}

runtime_record_failure() {
  local severity="$1"
  local name="$2"
  local reason="$3"
  local log_file="${4:-}"
  local fix="${5:-}"

  case "$severity" in
    critical | recoverable) ;;
    *) severity="recoverable" ;;
  esac

  runtime_record "$severity" "$name" "$reason" "$log_file" "$fix"
}

runtime_acquire_lock() {
  local lock_name="$1"
  local display_name="${2:-$1}"
  local lock_dir="${DOTFILES_RUNTIME_LOCK_ROOT}/${lock_name}.lock"
  local lock_pid=""

  mkdir -p "$DOTFILES_RUNTIME_LOCK_ROOT"
  if mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "${lock_dir}/pid"
    DOTFILES_RUNTIME_HELD_LOCKS+=("$lock_dir")
    return 0
  fi

  if [[ -f "${lock_dir}/pid" ]]; then
    lock_pid="$(cat "${lock_dir}/pid" 2>/dev/null || true)"
    if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
      runtime_warn "Removing stale dotfiles lock ${lock_dir}"
      rm -rf "$lock_dir" 2>/dev/null || true
      if mkdir "$lock_dir" 2>/dev/null; then
        printf '%s\n' "$$" > "${lock_dir}/pid"
        DOTFILES_RUNTIME_HELD_LOCKS+=("$lock_dir")
        return 0
      fi
    fi
  fi

  runtime_record_failure critical "$display_name" "another dotfiles process holds ${lock_dir}" "" "Wait for the other setup run to finish, then rerun the command."
  runtime_warn "Another dotfiles process holds ${lock_dir}"
  return 1
}

runtime_release_locks() {
  local lock_dir
  local restore_nounset=0

  case "$-" in *u*) restore_nounset=1; set +u ;; esac
  for lock_dir in "${DOTFILES_RUNTIME_HELD_LOCKS[@]}"; do
    rm -rf "$lock_dir" 2>/dev/null || true
  done
  DOTFILES_RUNTIME_HELD_LOCKS=()
  [[ "$restore_nounset" -eq 1 ]] && set -u
}

runtime_release_lock() {
  local lock_name="$1"
  local lock_dir="${DOTFILES_RUNTIME_LOCK_ROOT}/${lock_name}.lock"
  local next_locks=()
  local held
  local restore_nounset=0

  rm -rf "$lock_dir" 2>/dev/null || true
  case "$-" in *u*) restore_nounset=1; set +u ;; esac
  for held in "${DOTFILES_RUNTIME_HELD_LOCKS[@]}"; do
    [[ "$held" == "$lock_dir" ]] && continue
    next_locks+=("$held")
  done
  DOTFILES_RUNTIME_HELD_LOCKS=("${next_locks[@]}")
  [[ "$restore_nounset" -eq 1 ]] && set -u
}

runtime_acquire_global_lock() {
  if [[ "${DOTFILES_SETUP_GLOBAL_LOCK_HELD:-0}" == "1" ]]; then
    return 0
  fi

  runtime_acquire_lock "setup-bootstrap" "setup lock" || return 1
  DOTFILES_SETUP_GLOBAL_LOCK_HELD=1
  DOTFILES_RUNTIME_OWNS_GLOBAL_LOCK=1
  export DOTFILES_SETUP_GLOBAL_LOCK_HELD
}

runtime_run_job() {
  local name="$1"
  local severity="$2"
  local fix="$3"
  local safe_name log_file status
  shift 3

  safe_name="$(runtime_sanitize_name "$name")"
  log_file="$(mktemp "${DOTFILES_SETUP_LOG_DIR}/${safe_name}.XXXXXX")"

  if [[ "${DOTFILES_SETUP_SERIAL:-0}" == "1" ]]; then
    runtime_log "Running ${name}"
    set +e
    "$@" > "$log_file" 2>&1
    status=$?
    set -e
    if [[ "$status" -eq 0 ]]; then
      runtime_record_completed "$name"
      if [[ "${DOTFILES_SETUP_SHOW_STEP_LOGS:-0}" == "1" ]]; then
        cat "$log_file"
      fi
    else
      runtime_warn "${name} failed with status ${status}"
      runtime_record_failure "$severity" "$name" "exited with status ${status}" "$log_file" "$fix"
      DOTFILES_JOB_FAILED=1
    fi
    return 0
  fi

  runtime_log "Starting ${name} in background"
  "$@" > "$log_file" 2>&1 &
  DOTFILES_JOB_PIDS+=("$!")
  DOTFILES_JOB_NAMES+=("$name")
  DOTFILES_JOB_SEVERITIES+=("$severity")
  DOTFILES_JOB_FIXES+=("$fix")
  DOTFILES_JOB_LOGS+=("$log_file")
}

runtime_wait_jobs() {
  local i pid name severity fix log_file status failed="$DOTFILES_JOB_FAILED"

  for ((i = 0; i < ${#DOTFILES_JOB_PIDS[@]}; i++)); do
    pid="${DOTFILES_JOB_PIDS[$i]}"
    name="${DOTFILES_JOB_NAMES[$i]}"
    severity="${DOTFILES_JOB_SEVERITIES[$i]}"
    fix="${DOTFILES_JOB_FIXES[$i]}"
    log_file="${DOTFILES_JOB_LOGS[$i]}"

    runtime_log "Waiting for ${name}"
    set +e
    wait "$pid"
    status=$?
    set -e

    if [[ "$status" -eq 0 ]]; then
      runtime_record_completed "$name"
      runtime_log "${name} completed"
      if [[ "${DOTFILES_SETUP_SHOW_STEP_LOGS:-0}" == "1" ]]; then
        cat "$log_file"
      fi
    else
      failed=1
      runtime_warn "${name} failed with status ${status}"
      runtime_record_failure "$severity" "$name" "exited with status ${status}" "$log_file" "$fix"
    fi
  done

  DOTFILES_JOB_PIDS=()
  DOTFILES_JOB_NAMES=()
  DOTFILES_JOB_SEVERITIES=()
  DOTFILES_JOB_FIXES=()
  DOTFILES_JOB_LOGS=()
  DOTFILES_JOB_FAILED=0
  return "$failed"
}

runtime_cleanup_jobs() {
  local pid
  local restore_nounset=0

  case "$-" in *u*) restore_nounset=1; set +u ;; esac
  for pid in "${DOTFILES_JOB_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  DOTFILES_JOB_PIDS=()
  DOTFILES_JOB_FAILED=0
  [[ "$restore_nounset" -eq 1 ]] && set -u
}

runtime_run_step() {
  DOTFILES_SETUP_SERIAL=1 runtime_run_job "$@"
}

runtime_print_section() {
  local kind="$1"
  local title="$2"
  local found=0
  local record_kind name reason log_file fix

  printf '\n%s\n' "$title"
  while IFS=$'\t' read -r record_kind name reason log_file fix || [[ -n "${record_kind:-}" ]]; do
    [[ "$record_kind" == "$kind" ]] || continue
    found=1
    printf '%s' "- ${name}"
    [[ -n "$reason" ]] && printf ': %s' "$reason"
    printf '\n'
    [[ -n "$fix" ]] && printf '  fix: %s\n' "$fix"
    if [[ -n "$log_file" && -f "$log_file" ]]; then
      printf '  log: %s\n' "$log_file"
      tail -40 "$log_file" | sed 's/^/    /'
    fi
  done < "$DOTFILES_SETUP_SUMMARY_FILE"

  if [[ "$found" -eq 0 ]]; then
    printf '%s\n' "- none"
  fi
}

runtime_print_summary() {
  printf '\nSetup result summary\n'
  runtime_print_section completed "Completed"
  runtime_print_section recoverable "Failed but recoverable"
  runtime_print_section deferred "Deferred/manual"
  runtime_print_section critical "Critical failure"
}

runtime_has_failures() {
  grep -Eq '^(critical|recoverable)	' "$DOTFILES_SETUP_SUMMARY_FILE"
}

runtime_exit_status() {
  if runtime_has_failures; then
    return 1
  fi
  return 0
}

runtime_cleanup() {
  runtime_cleanup_jobs
  runtime_release_locks
}
