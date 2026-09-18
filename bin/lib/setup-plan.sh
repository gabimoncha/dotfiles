#!/usr/bin/env bash
# One dependency plan for execution and simulation. Bash 3.2 compatible.
plan_ids=()
plan_states=()
plan_jobs=()
plan_status=0

plan_state() {
  local i
  for ((i=0; i<${#plan_ids[@]}; i++)); do
    if [[ "${plan_ids[$i]}" == "$1" ]]; then printf '%s' "${plan_states[$i]}"; return; fi
  done
  printf 'unknown'
}

plan_set() {
  local i
  for ((i=0; i<${#plan_ids[@]}; i++)); do
    if [[ "${plan_ids[$i]}" == "$1" ]]; then plan_states[$i]="$2"; return; fi
  done
  plan_ids+=("$1"); plan_states+=("$2")
}

plan_ready() {
  local prerequisite state
  for prerequisite in $1; do
    state="$(plan_state "$prerequisite")"
    case "$state" in completed|planned) ;; *) return 1 ;; esac
  done
}

plan_stage() {
  local id="$1" parent="$2" prerequisites="$3" mode="$4" status=0
  shift 4
  if ! plan_ready "$prerequisites"; then
    runtime_warn "$id blocked: prerequisites not ready ($prerequisites)"
    runtime_stage_begin "$id" "$parent" "$prerequisites"
    runtime_stage_end "$id" blocked 1
    plan_set "$id" blocked
    plan_status=1
    return 0
  fi
  if [[ "${DOTFILES_RUN_MODE:-normal}" == dry-run && "$mode" != probe ]]; then
    runtime_stage_begin "$id" "$parent" "$prerequisites"
    runtime_stage_end "$id" planned 0
    plan_set "$id" planned
    return 0
  fi
  if [[ "$mode" == probe ]]; then
    runtime_event probe "$id" "$parent" '' 0 'Executing read-only preflight probes' "$prerequisites"
  fi
  runtime_execute_stage "$id" "$parent" "$prerequisites" "$mode" "$@" || status=$?
  case "$status" in
    0) plan_set "$id" completed ;;
    20)
      plan_set "$id" deferred
      # Only an explicit user opt-out is optional at this planner level.
      [[ "$id" == touch_id && "${DOTFILES_SKIP_SUDO_TOUCH_ID:-0}" == 1 ]] || plan_status=1
      ;;
    *) plan_set "$id" failed; plan_status=1 ;;
  esac
}

plan_start() {
  local id="$1" parent="$2" prerequisites="$3" mode="$4" index
  shift 4
  if [[ "${DOTFILES_SETUP_SERIAL:-0}" == 1 || "${DOTFILES_RUN_MODE:-normal}" == dry-run ]] || ! plan_ready "$prerequisites"; then
    plan_stage "$id" "$parent" "$prerequisites" "$mode" "$@"
    return
  fi
  # runtime jobs own their descendants and logs; parent waits by stable index.
  index=${#DOTFILES_JOB_PIDS[@]}
  DOTFILES_NEXT_STAGE_ID="$id" DOTFILES_NEXT_PARENT_ID="$parent" DOTFILES_NEXT_PREREQUISITES="$prerequisites" \
    runtime_run_job "$id" recoverable "Rerun ./bin/setup after repairing this stage." "$@"
  plan_jobs+=("$id:$index")
  plan_set "$id" running
}

plan_wait() {
  local entry index status=0
  [[ "$(plan_state "$1")" == running ]] || return 0
  for entry in "${plan_jobs[@]}"; do
    [[ "${entry%:*}" == "$1" ]] || continue
    index="${entry##*:}"
    runtime_wait_job "$index" || status=$?
    if [[ "$status" == 0 ]]; then plan_set "$1" completed
    elif [[ "$status" == 20 ]]; then plan_set "$1" deferred; plan_status=1
    else plan_set "$1" failed; plan_status=1; fi
    return 0
  done
}

plan_defer() {
  runtime_stage_begin "$1" "$2" "${3:-}"
  runtime_stage_end "$1" deferred 0
  plan_set "$1" deferred
}

setup_plan() {
  runtime_stage_begin setup "" ""
  local group plan_started=$SECONDS
  for group in foundations github packages mobile environment restore; do
    runtime_stage_begin "$group" setup ''
  done
  plan_stage preflight setup '' probe setup_preflight
  plan_stage clt setup 'preflight' capture setup_clt
  plan_stage touch_id environment 'clt' sensitive setup_touch_id
  plan_stage sudo foundations 'clt' sensitive setup_sudo
  plan_stage sudo_keepalive foundations 'sudo' local setup_keepalive
  plan_start homebrew foundations 'clt sudo' capture setup_homebrew
  plan_start mise foundations 'clt' capture setup_mise
  plan_wait mise
  plan_stage install_gh github 'mise' capture setup_install_gh
  if [[ "${DOTFILES_SETUP_PHASE:-continue}" == prepare ]]; then
    plan_wait homebrew
    plan_stage brew_environment foundations 'homebrew' local setup_brew_environment
    plan_stage standalone_agents foundations 'brew_environment' capture setup_standalone_agents
    if [[ "$plan_status" == 0 ]]; then
      plan_stage permission_handoff foundations 'homebrew mise install_gh standalone_agents' capture setup_permission_handoff
    else
      runtime_warn 'Foundation setup is incomplete. Fix the failed stages and rerun ./bin/setup before continuing.'
    fi
    setup_plan_finish "$plan_started"
    return "$plan_status"
  fi
  plan_stage links_before_packages environment 'clt' capture setup_links
  plan_stage authenticate_api github 'install_gh' sensitive setup_api
  plan_stage authenticate_ssh github 'authenticate_api' sensitive setup_ssh
  # SSH and API have separate readiness: API success survives SSH failure.
  plan_stage verify_mise_access github 'authenticate_api links_before_packages' sensitive setup_verify_auth
  if [[ "$(plan_state verify_mise_access)" == completed ]]; then
    export DOTFILES_SETUP_API_READY=1
  else
    export DOTFILES_SETUP_API_READY=0
  fi
  plan_wait homebrew
  plan_stage brew_environment foundations 'homebrew' local setup_brew_environment
  plan_stage service_links environment 'brew_environment links_before_packages' capture setup_links
  plan_stage brewfiles packages 'brew_environment service_links' local setup_brewfiles
  plan_start homebrew_inventory packages 'brewfiles' capture setup_brew_inventory
  if [[ "${DOTFILES_SKIP_MOBILE_DEV:-0}" == 1 ]]; then
    plan_defer mobile_tools mobile ''
  else
    plan_stage mobile_tools mobile 'brew_environment verify_mise_access' capture setup_mobile_tools
  fi
  plan_start mise_inventory packages 'brew_environment verify_mise_access links_before_packages' capture setup_mise_inventory
  if [[ "${DOTFILES_SKIP_MOBILE_DEV:-0}" == 1 ]]; then
    plan_defer xcode mobile ''
  else
    # Finish background output before handing the terminal to Apple sign-in.
    plan_wait homebrew_inventory
    plan_wait mise_inventory
    plan_stage xcode mobile 'mobile_tools' sensitive setup_xcode
  fi
  plan_stage submodules environment 'clt' capture setup_submodules
  plan_wait homebrew_inventory
  plan_stage manifest_apps packages 'brew_environment' capture setup_manifest_apps
  plan_stage applications packages 'brew_environment' capture setup_verify_apps
  plan_stage editor_extensions packages 'brewfiles' capture setup_editor_extensions
  plan_wait mise_inventory
  plan_stage app_store packages 'brewfiles' capture setup_app_store
  # Verify individual tools even when the inventory was only partly installed.
  plan_stage capabilities environment 'mise' capture setup_capabilities
  plan_stage shell environment 'mise' capture setup_shell
  plan_stage standalone_agents packages 'brew_environment' capture setup_standalone_agents
  plan_stage skills_runtime environment 'mise' capture setup_skills_runtime
  plan_stage skills environment 'skills_runtime' sensitive setup_skills
  plan_stage restores restore 'clt' sensitive setup_restores
  plan_wait xcode
  if [[ "${DOTFILES_SKIP_MOBILE_DEV:-0}" == 1 ]]; then
    plan_defer mobile_finish mobile ''
  else
    plan_stage mobile_finish mobile 'xcode brew_environment' capture setup_mobile_finish
  fi
  plan_stage final_links environment 'mise_inventory standalone_agents' capture setup_final_links
  plan_stage defaults environment 'clt' sensitive setup_defaults
  plan_stage screenshots environment 'clt' capture setup_screenshots
  plan_stage app_settings environment 'clt' sensitive setup_app_settings
  plan_stage finder environment 'clt' sensitive setup_finder
  setup_plan_finish "$plan_started"
  return "$plan_status"
}

setup_plan_finish() {
  local plan_started="$1" group
  for group in foundations github packages mobile environment restore; do
    runtime_event group_end "$group" setup '' 0 'group scheduling finished; inspect child outcomes'
  done
  DOTFILES_STAGE_ID=setup
  DOTFILES_STAGE_PARENT=''
  DOTFILES_STAGE_PREREQUISITES=''
  DOTFILES_STAGE_STARTED="$plan_started"
  if [[ "$plan_status" != 0 ]]; then runtime_stage_end setup failed 1
  elif [[ "${DOTFILES_RUN_MODE:-normal}" == dry-run ]]; then runtime_stage_end setup planned 0
  else runtime_stage_end setup completed 0; fi
  return "$plan_status"
}
