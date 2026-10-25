#!/usr/bin/env bash
# The machine profile selects one mise.<profile>.toml file at the repository
# root: pro and air on macOS, container and vm on Linux. Bash 3.2 compatible.

# Accept the profile names that older versions of this repository used.
dotfiles_profile_normalize() {
  case "${1:-}" in
    macos/pro) printf 'pro\n' ;;
    macos/air) printf 'air\n' ;;
    linux/container|linux-container) printf 'container\n' ;;
    linux/vm-gcp|linux-vm|vm-gcp) printf 'vm\n' ;;
    *) printf '%s\n' "${1:-}" ;;
  esac
}

# Callers run this check before they change machine state.
dotfiles_profile_validate() {
  local profile="${1:-}" system="${2:-$(uname -s)}"
  case "$profile" in
    pro|air)
      [[ "$system" == Darwin ]] || {
        printf 'dotfiles: profile %s requires macOS.\n' "$profile" >&2
        return 2
      }
      ;;
    container|vm)
      [[ "$system" == Linux ]] || {
        printf 'dotfiles: profile %s requires Linux.\n' "$profile" >&2
        return 2
      }
      ;;
    *) printf 'dotfiles: unsupported profile: %s. Use pro, air, container, or vm.\n' "$profile" >&2; return 2 ;;
  esac
  case "$profile" in
    air|vm)
      printf 'dotfiles: profile %s is not set up yet. No changes were made.\n' "$profile" >&2
      return 2
      ;;
  esac
}

# Prints the profile. DOTFILES_PROFILE wins, then env = ["<profile>"] in the
# ignored .miserc.local.toml. A Linux container without either uses container.
dotfiles_profile() {
  local root="${1:-}" profile="${DOTFILES_PROFILE:-}" saved line system
  local pattern='^[[:space:]]*env[[:space:]]*=[[:space:]]*\[[[:space:]]*"([a-z/-]+)"[[:space:]]*,?[[:space:]]*\][[:space:]]*$'
  if [[ -z "$root" ]]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || return
  fi
  system="$(uname -s)" || return
  saved="$root/.miserc.local.toml"
  # The old layout kept the selection here. bin/link-dotfiles moves it.
  [[ -e "$saved" || ! -e "$root/mise/setup/miserc.local.toml" ]] || saved="$root/mise/setup/miserc.local.toml"
  if [[ -z "$profile" && -e "$saved" ]]; then
    [[ -r "$saved" ]] || {
      printf 'dotfiles: cannot read %s.\n' "$saved" >&2
      return 2
    }
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      if [[ "$line" =~ $pattern ]]; then
        profile="${BASH_REMATCH[1]}"
      fi
    done < "$saved"
    [[ -n "$profile" ]] || {
      printf 'dotfiles: .miserc.local.toml has no profile. Add a line such as env = ["pro"].\n' >&2
      return 2
    }
  fi
  if [[ -z "$profile" ]]; then
    if [[ "$system" == Linux && ( -f /.dockerenv || -f /run/.containerenv ) ]]; then
      profile=container
    else
      printf 'dotfiles: select a profile. Save env = ["pro"] in %s, or set DOTFILES_PROFILE.\n' "$saved" >&2
      return 2
    fi
  fi
  profile="$(dotfiles_profile_normalize "$profile")" || return
  dotfiles_profile_validate "$profile" "$system" || return
  printf '%s\n' "$profile"
}
