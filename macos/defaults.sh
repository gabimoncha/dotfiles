#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '==> %s\n' "$1"
}

apply_symbolic_hotkey_changes() {
  local activate_settings="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

  defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys >/dev/null 2>&1 || true
  if [[ -x "$activate_settings" ]]; then
    "$activate_settings" -u >/dev/null 2>&1 || true
  fi
}

ensure_keyboard_input_sources() {
  if command -v swift >/dev/null 2>&1 && [[ -f "${script_dir}/ensure-input-sources.swift" ]]; then
    swift "${script_dir}/ensure-input-sources.swift"
    return 0
  fi

  if ! defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q '"KeyboardLayout Name" = "U.S."'; then
    defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add \
      '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 0; "KeyboardLayout Name" = "U.S."; }'
  fi

  if defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q '"KeyboardLayout Name" = "Romanian-Standard"'; then
    return 0
  fi

  defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add \
    '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = -38; "KeyboardLayout Name" = "Romanian-Standard"; }'
}

# The preferences, the Dock apps, and the login items of mise.macos.toml and
# the profile file.
log "Applying the macOS preferences in mise.macos.toml"
"${script_dir}/../bin/repo-mise" bootstrap macos defaults apply --yes

log "Applying input sources"
ensure_keyboard_input_sources

log "Applying screenshot defaults"
"${script_dir}/../bin/configure-screenshots"

# macowl and the Mac mini keep the display on. The MacBook Air keeps the macOS
# display sleep, to save its battery.
. "${script_dir}/../bin/lib/dotfiles-profile.sh"
if [[ "$(dotfiles_profile "${script_dir}/.." 2>/dev/null || true)" == air ]]; then
  log "Keeping the macOS display sleep settings on the MacBook Air"
else
  log "Applying display sleep defaults"
  sudo pmset -b displaysleep 0
  sudo pmset -c displaysleep 0
fi

log "Activating the Spotlight, Minimize, and Arrange shortcut changes"
apply_symbolic_hotkey_changes

log "Reloading affected macOS services"
killall cfprefsd >/dev/null 2>&1 || true
killall ControlCenter >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
killall TextInputMenuAgent >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

printf 'Applied macOS defaults.\n'
