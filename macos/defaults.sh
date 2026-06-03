#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '==> %s\n' "$1"
}

disable_symbolic_hotkey() {
  local key="$1"
  local plist="${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist"

  if /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:${key}" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled false" "$plist" >/dev/null 2>&1 || true
  fi
}

log "Applying global keyboard and locale defaults"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=RON"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool true
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool true
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

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

log "Applying Dock defaults"
defaults write com.apple.dock largesize -int 51
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock tilesize -int 34

log "Applying Activity Monitor defaults"
defaults write com.apple.ActivityMonitor SortDirection -int 1

log "Applying software update defaults"
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true

log "Disabling Spotlight shortcuts for Raycast"
disable_symbolic_hotkey 64
disable_symbolic_hotkey 65

log "Reloading affected macOS services"
killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

printf 'Applied macOS defaults.\n'
