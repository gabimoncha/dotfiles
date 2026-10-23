#!/usr/bin/env bash

# These functions validate the profile before a caller changes machine state.
dotfiles_profile_validate() {
  local profile="${1:-}" system="${2:-$(uname -s)}"
  case "$profile" in
    macos/pro|macos/air)
      [[ "$system" == Darwin ]] || {
        printf 'dotfiles: profile %s requires macOS.\n' "$profile" >&2
        return 2
      }
      ;;
    linux/container|linux/vm-gcp)
      [[ "$system" == Linux ]] || {
        printf 'dotfiles: profile %s requires Linux.\n' "$profile" >&2
        return 2
      }
      ;;
    *) printf 'dotfiles: unsupported profile: %s\n' "$profile" >&2; return 2 ;;
  esac
  case "$profile" in
    macos/air|linux/vm-gcp)
      printf 'dotfiles: profile %s is deferred. No changes were made.\n' "$profile" >&2
      return 2
      ;;
  esac
}

dotfiles_profile_env() {
  case "${1:-}" in
    macos/pro) printf 'pro\n' ;;
    linux/container) printf 'container\n' ;;
    *) printf 'dotfiles: no setup environment for profile %s.\n' "${1:-}" >&2; return 2 ;;
  esac
}

dotfiles_profile() {
  local root="${1:-}" profile="${DOTFILES_PROFILE:-}" selected="" system
  if [[ -z "$root" ]]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || return
  fi
  system="$(uname -s)" || return
  if [[ -z "$profile" && -e "$root/mise/setup/miserc.local.toml" ]]; then
    local saved_line saved_selection=""
    local selector_pattern='^[[:space:]]*env[[:space:]]*=[[:space:]]*\[[[:space:]]*"(pro|air|container|vm-gcp)"[[:space:]]*,?[[:space:]]*\][[:space:]]*$'
    [[ -r "$root/mise/setup/miserc.local.toml" ]] || {
      printf 'dotfiles: cannot read the saved setup profile.\n' >&2
      return 2
    }
    while IFS= read -r saved_line || [[ -n "$saved_line" ]]; do
      saved_selection+=" ${saved_line%%#*}"
    done < "$root/mise/setup/miserc.local.toml"
    if [[ "$saved_selection" =~ $selector_pattern ]]; then
      selected="${BASH_REMATCH[1]}"
    else
      printf 'dotfiles: invalid saved setup profile. Use env = ["pro"] or env = ["container"].\n' >&2
      return 2
    fi
    case "$selected" in
      pro|air) profile="macos/$selected" ;;
      container|vm-gcp) profile="linux/$selected" ;;
    esac
  fi
  if [[ -z "$profile" ]]; then
    if [[ "$system" == Linux && ( -f /.dockerenv || -f /run/.containerenv ) ]]; then
      profile=linux/container
    elif [[ "$system" == Linux ]]; then
      printf 'dotfiles: Linux VM setup is deferred. Select a supported profile explicitly.\n' >&2
      return 2
    else
      printf 'dotfiles: select DOTFILES_PROFILE=macos/pro or save env = ["pro"] in mise/setup/miserc.local.toml.\n' >&2
      return 2
    fi
  fi
  dotfiles_profile_validate "$profile" "$system" || return
  printf '%s\n' "$profile"
}
