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

dock_persistent_app_is_allowed() {
  case "$1" in
    com.apple.apps.launcher | \
      com.apple.Safari | \
      com.apple.Photos | \
      com.apple.FaceTime | \
      com.apple.AppStore | \
      com.apple.campo | \
      com.apple.systempreferences)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

prune_dock_persistent_apps() {
  local plist="${HOME}/Library/Preferences/com.apple.dock.plist"
  local app_count index bundle_id

  if [[ ! -f "$plist" ]]; then
    return 0
  fi

  app_count="$(plutil -extract persistent-apps raw "$plist" 2>/dev/null || printf '0')"
  if [[ ! "$app_count" =~ ^[0-9]+$ ]]; then
    return 0
  fi

  for ((index = app_count - 1; index >= 0; index--)); do
    bundle_id="$(/usr/libexec/PlistBuddy -c "Print :persistent-apps:${index}:tile-data:bundle-identifier" "$plist" 2>/dev/null || true)"
    if [[ -n "$bundle_id" ]] && ! dock_persistent_app_is_allowed "$bundle_id"; then
      /usr/libexec/PlistBuddy -c "Delete :persistent-apps:${index}" "$plist" >/dev/null
    fi
  done
}

log "Applying the macOS preferences in mise.macos.toml"
"${script_dir}/../bin/repo-mise" bootstrap macos defaults apply --yes

log "Applying input sources"
ensure_keyboard_input_sources

log "Applying screenshot defaults"
"${script_dir}/../bin/configure-screenshots"

log "Removing Dock apps that are not allowed"
prune_dock_persistent_apps

log "Applying display sleep defaults"
sudo pmset -b displaysleep 0
sudo pmset -c displaysleep 0

log "Activating the Spotlight and Minimize shortcut changes"
apply_symbolic_hotkey_changes

log "Reloading affected macOS services"
killall cfprefsd >/dev/null 2>&1 || true
killall ControlCenter >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
killall TextInputMenuAgent >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

printf 'Applied macOS defaults.\n'
