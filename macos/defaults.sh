#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '==> %s\n' "$1"
}

set_disabled_symbolic_hotkey() {
  local key="$1"
  local key_code="$2"
  local modifiers="$3"
  local plist="${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist"

  if ! /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys dict" "$plist" >/dev/null 2>&1
  fi

  /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:${key}" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy \
    -c "Add :AppleSymbolicHotKeys:${key} dict" \
    -c "Add :AppleSymbolicHotKeys:${key}:enabled bool false" \
    -c "Add :AppleSymbolicHotKeys:${key}:value dict" \
    -c "Add :AppleSymbolicHotKeys:${key}:value:type string standard" \
    -c "Add :AppleSymbolicHotKeys:${key}:value:parameters array" \
    -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:0 integer 32" \
    -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:1 integer ${key_code}" \
    -c "Add :AppleSymbolicHotKeys:${key}:value:parameters:2 integer ${modifiers}" \
    "$plist" >/dev/null
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

  if defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q '"KeyboardLayout Name" = "Romanian"'; then
    return 0
  fi

  defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add \
    '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = -39; "KeyboardLayout Name" = "Romanian"; }'
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

log "Applying global keyboard and locale defaults"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=RON"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain KB_SpellingLanguage -dict KB_SpellingLanguageIsAutomatic -bool true
defaults write NSGlobalDomain NSSpellCheckerAutomaticallyIdentifiesLanguages -bool true
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

log "Applying input source and dictation defaults"
ensure_keyboard_input_sources
defaults write com.apple.assistant.support "Dictation Enabled" -bool true
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMNetworkBasedLocaleIdentifier -string "ro_RO"
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMPreferredLanguageIdentifiers -array "ro_RO" "en_US"
defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs VisibleNetworkSRLocaleIdentifiers -dict "ro_RO" -bool true "en_US" -bool true

log "Applying pointer and trackpad defaults"
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 1.7
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string "OneButton"
defaults write com.apple.AppleMultitouchMouse MouseHorizontalScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseMomentumScroll -bool true
defaults write com.apple.AppleMultitouchMouse MouseOneFingerDoubleTapGesture -int 1
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false

log "Applying Finder defaults"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

log "Applying screenshot defaults"
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

log "Applying Dock defaults"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock largesize -int 51
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.dock tilesize -int 34
prune_dock_persistent_apps

log "Applying Control Center and menu bar defaults"
defaults -currentHost write com.apple.controlcenter Battery -int 19
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

log "Applying Activity Monitor defaults"
defaults write com.apple.ActivityMonitor SortDirection -int 1

log "Applying software update defaults"
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true

log "Applying display sleep defaults"
sudo pmset -b displaysleep 0
sudo pmset -c displaysleep 0

log "Disabling Spotlight shortcuts for Raycast"
set_disabled_symbolic_hotkey 64 49 1048576
set_disabled_symbolic_hotkey 65 49 1572864
apply_symbolic_hotkey_changes

log "Reloading affected macOS services"
killall cfprefsd >/dev/null 2>&1 || true
killall ControlCenter >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
killall TextInputMenuAgent >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

printf 'Applied macOS defaults.\n'
