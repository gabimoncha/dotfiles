#!/usr/bin/env bash
# Read-only mobile state checks shared by check-mobile-ready and install-mobile-dev.
# Callers set repo_root.

mobile_applications_dir="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
mobile_plistbuddy_bin="${DOTFILES_PLISTBUDDY_BIN:-/usr/libexec/PlistBuddy}"
# Mac App Store id of Xcode. brew bundle cannot install it because mas needs sudo.
mobile_xcode_app_store_id=497799835

mobile_selected_xcode_app() {
  local developer_dir
  developer_dir="$(xcode-select -p 2>/dev/null || true)"
  [[ "$developer_dir" == "$mobile_applications_dir"/Xcode*.app/Contents/Developer && -d "$developer_dir" ]] || return 1
  printf '%s\n' "${developer_dir%/Contents/Developer}"
}

mobile_xcode_build() {
  "$mobile_plistbuddy_bin" -c 'Print :DTXcodeBuild' "$1/Contents/Info.plist" 2>/dev/null || true
}

# The App Store offers only public releases. Otherwise use the bin/preflight
# rule: a prerelease build ends in a lowercase letter.
mobile_xcode_is_public() {
  local name build
  [[ -f "$1/Contents/_MASReceipt/receipt" ]] && return 0
  name="$(basename "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]')"
  build="$(mobile_xcode_build "$1")"
  [[ "$name" != *beta* && -n "$build" && "$build" != *[[:lower:]] ]]
}

# An interrupted download can leave an incomplete bundle.
mobile_xcode_complete() {
  [[ -d "$1/Contents/Developer" && -n "$(mobile_xcode_build "$1")" ]]
}

# xcodebuild refuses to list SDKs until the license is accepted.
mobile_ios_sdk_ready() {
  local sdks
  sdks="$(xcodebuild -showsdks 2>/dev/null)" || return 1
  [[ "$sdks" == *iphonesimulator* ]]
}

mobile_ios_runtime_ready() {
  xcrun simctl list runtimes 2>/dev/null |
    awk '/com\.apple\.CoreSimulator\.SimRuntime\.iOS-/ && $0 !~ /\(unavailable/ { found = 1 } END { exit found ? 0 : 1 }'
}

mobile_android_studio_ready() {
  [[ -d "${mobile_applications_dir}/Android Studio.app" ]]
}

mobile_formulae() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]] && printf '%s\n' "${BASH_REMATCH[1]##*/}"
  done < "${repo_root}/apps/mobile.Brewfile"
  return 0
}

mobile_formula_installed() {
  brew list --formula "$1" >/dev/null 2>&1
}
