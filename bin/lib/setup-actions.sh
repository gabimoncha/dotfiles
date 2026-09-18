#!/usr/bin/env bash
# Mutating actions are called only by the normal-run side of setup-plan.sh.
setup_preflight() { "${repo_root}/bin/preflight"; }
setup_clt() {
  if xcode-select -p >/dev/null 2>&1; then return 0; fi
  xcode-select --install || true
  warn 'Finish the Command Line Tools installer, then rerun ./bin/setup.'
  return 1
}
setup_touch_id() {
  [[ "${DOTFILES_SKIP_SUDO_TOUCH_ID:-0}" == 1 ]] && return 20
  "${repo_root}/bin/configure-sudo-touch-id" --enable
}
setup_sudo() { ensure_admin_user; sudo -v; }
setup_keepalive() {
  (while sudo -n true; do sleep 30; done) >/dev/null 2>&1 &
}
setup_homebrew() { ensure_homebrew; }
setup_mise() { "${repo_root}/bin/ensure-mise-standalone" --skip-update; }
setup_install_gh() { "${repo_root}/bin/github-bootstrap" install-gh; }
setup_api() { "${repo_root}/bin/auth-setup" --api-only; }
setup_ssh() { "${repo_root}/bin/auth-setup" --ssh-only; }
setup_verify_auth() { "${repo_root}/bin/auth-setup" --verify-mise; }
setup_links() { DOTFILES_LINK_AGENT_CONFIG=0 "${repo_root}/bin/link-dotfiles"; }
setup_final_links() { DOTFILES_LINK_AGENT_CONFIG=1 "${repo_root}/bin/link-dotfiles"; }
setup_brew_environment() { load_homebrew_shellenv; }
setup_brewfiles() {
  log "Preparing Homebrew inventory (checking existing apps; no casks installed in this step)"
  prepare_brewfiles
}
setup_brew_inventory() { install_brewfile; }
setup_mise_inventory() { install_and_check_mise_tools; }
setup_manifest_apps() { "${repo_root}/bin/install-apps"; }
setup_app_store() { install_mas_apps; }
setup_editor_extensions() { install_vscode_extensions; }
setup_submodules() { initialize_submodules; }
setup_capabilities() { "${repo_root}/bin/check-mise-tools"; }
setup_shell() {
  local status=0
  install_shell_framework || status=1
  local tmux_path
  if tmux_path="$(setup_real_tool tmux)"; then PATH="$(dirname "$tmux_path"):$PATH" "${repo_root}/bin/setup-tmux" || status=1; fi
  return "$status"
}
setup_standalone_agents() {
  local status=0
  "${repo_root}/bin/ensure-codex-standalone" || status=1
  "${repo_root}/bin/ensure-cursor-agent-standalone" || status=1
  return "$status"
}
setup_app_settings() { "${repo_root}/bin/configure-app-settings"; }
setup_screenshots() { "${repo_root}/bin/configure-screenshots"; }
setup_permission_handoff() {
  "${repo_root}/bin/configure-app-settings" --permissions-only
  cat <<'INSTRUCTIONS'
Foundation installation finished. This phase does not install the bulk app inventory.

Before continuing:
1. Open System Settings > Privacy & Security > App Management.
2. Enable the terminal application you will use for setup, if listed; use Add
   if macOS offers it. Approve App Management when macOS requests it.
   Setup cannot grant or reliably verify this permission. If the app is not
   available to select, the first protected app operation may still prompt.
3. Once this command exits, fully quit and reopen that terminal application
   (not just its tab), as requested by macOS. Stop other work in it first.
4. Return to this repository and run: ./bin/setup --continue

--continue acknowledges this manual checkpoint; it does not assert that macOS
permissions were detected. Do not grant Full Disk Access or Accessibility just
for package installation. App-specific consent is handled later, as needed.
Both phases retain live output and private diagnostic logs.
INSTRUCTIONS
}
setup_mobile_tools() {
  [[ "${DOTFILES_SKIP_MOBILE_DEV:-0}" == 1 ]] && return 20
  "${repo_root}/bin/install-mobile-dev" --prepare-tools-only
}
setup_xcode() { "${repo_root}/bin/install-mobile-dev" --xcode-install-only; }
setup_mobile_finish() {
  local status=0
  "${repo_root}/bin/install-mobile-dev" --android-only || status=1
  "${repo_root}/bin/install-mobile-dev" --ios-platform-only || status=1
  "${repo_root}/bin/install-mobile-dev" --xcode-formulae-only || status=1
  return "$status"
}
setup_skills_runtime() {
  local node
  node="$(setup_real_tool node)" || return 1
  "$node" --version >/dev/null 2>&1
}
setup_skills() {
  local source_ref="${DOTFILES_REVIEWED_SKILLS_REF:-}" node
  # Mutable remote skill code is not silently trusted during recovery.
  if [[ ! "$source_ref" =~ ^[0-9a-f]{40}$ ]]; then
    runtime_record_deferred 'Personal skills' 'set DOTFILES_REVIEWED_SKILLS_REF to a reviewed repository commit' 'Review the skill source, then rerun setup with the reviewed commit.'
    return 20
  fi
  node="$(setup_real_tool node)" || return 1
  # Require a reviewed installed skills CLI rather than executing latest code.
  local skills
  skills="$(setup_real_tool skills)" || { warn 'Install a reviewed skills CLI version explicitly before importing skills.'; return 20; }
  PATH="$(dirname "$node"):$PATH" "$skills" --version >/dev/null 2>&1 || return 1
  PATH="$(dirname "$node"):$PATH" "$skills" add "https://github.com/gabimoncha/skills/tree/${source_ref}" -g --skill '*' --agent claude-code cursor codex -y
}
setup_defaults() { apply_macos_defaults_once; }
setup_finder() { "${repo_root}/bin/finder-sidebar-favorites"; }

setup_verify_apps() {
  local key type token bundle notes status=0
  while IFS=$'\t' read -r key type token bundle notes || [[ -n "${key:-}" ]]; do
    [[ -n "${key:-}" && "$key" != \#* ]] || continue
    case "$type" in
      cask)
        if [[ "$bundle" != - && -n "$bundle" ]]; then
          if [[ ! -d "${DOTFILES_APPLICATIONS_DIR:-/Applications}/${bundle}.app" ]]; then
            runtime_record_failure recoverable "app.$key" "application bundle is unavailable"
            status=1
          fi
        elif ! brew list --cask "$token" >/dev/null 2>&1; then status=1; fi
        ;;
      formula) brew list --formula "$token" >/dev/null 2>&1 || status=1 ;;
      manual)
        [[ -d "${DOTFILES_APPLICATIONS_DIR:-/Applications}/${bundle}.app" ]] || runtime_record_deferred "app.$key" 'vendor installation requires manual completion'
        ;;
    esac
  done < "${repo_root}/apps/manifest.tsv"
  return "$status"
}
