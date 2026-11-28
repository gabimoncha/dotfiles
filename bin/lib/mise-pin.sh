#!/usr/bin/env bash
# The standalone mise release that setup installs. mise.toml sets the same
# version as a soft min_version, and configs/mise/config/config.toml as a hard
# one. Bash 3.2 compatible.
#
# Change the version and the installer digest together. The digest is the
# release's install.sh digest in GitHub's release metadata. Raise the pin only
# when this repository needs a newer release. mise updates itself without the
# four-day delay, so the installed mise is often newer than the pin.
# The macOS files need 2026.11.8, the first release that reads
# [bootstrap.settings.macos]. The pin is 2026.11.14, the release that every
# fleet host runs, so a new machine gets the mise that the others use.
pinned_mise_version=2026.11.14
pinned_installer_sha256=ef67c7eb5845bd1332b6adc07bbf044a3ae10acdd4e8281a9ad6ba035205d101

# An older mise can refuse the current global config, so read only its version.
mise_installed_version() {
  local output
  [[ -x "$1" ]] || return 1
  output="$(cd / && MISE_GLOBAL_CONFIG_FILE=/dev/null MISE_SELF_UPDATE_AUTO=0 "$1" --version 2>/dev/null)" || return 1
  output="${output%% *}"
  output="${output%-DEBUG}"
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  printf '%s\n' "$output"
}

mise_version_at_least() {
  awk -v have="$1" -v want="$2" 'BEGIN {
    split(have, h, "."); split(want, w, ".")
    for (i = 1; i <= 3; i++) {
      if (h[i] + 0 > w[i] + 0) exit 0
      if (h[i] + 0 < w[i] + 0) exit 1
    }
    exit 0
  }'
}

# Succeeds when the mise at path $1 is the pinned release or newer.
mise_at_pin() {
  local version
  version="$(mise_installed_version "$1")" || return 1
  mise_version_at_least "$version" "$pinned_mise_version"
}
