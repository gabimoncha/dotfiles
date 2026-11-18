#!/usr/bin/env bash
# The machine profile selects one mise.<profile>.toml file at the repository
# root: macowl, macmini, and air on macOS, and container on Linux. A macOS
# profile can also have app lists in apps/. The development machines, every
# profile except air, also load the devhost layer before their own files.
# Bash 3.2 compatible.

# Accept the profile names that older versions of this repository used.
dotfiles_profile_normalize() {
  case "${1:-}" in
    macos/pro | pro) printf 'macowl\n' ;;
    macos/air) printf 'air\n' ;;
    linux/container | linux-container) printf 'container\n' ;;
    *) printf '%s\n' "${1:-}" ;;
  esac
}

# Callers run this check before they change machine state.
dotfiles_profile_validate() {
  local profile="${1:-}" system="${2:-$(uname -s)}"
  case "$profile" in
    macowl | macmini | air)
      [[ "$system" == Darwin ]] || {
        printf 'dotfiles: profile %s requires macOS.\n' "$profile" >&2
        return 2
      }
      ;;
    container)
      [[ "$system" == Linux ]] || {
        printf 'dotfiles: profile %s requires Linux.\n' "$profile" >&2
        return 2
      }
      ;;
    *)
      printf 'dotfiles: unsupported profile: %s. Use macowl, macmini, air, or container.\n' "$profile" >&2
      return 2
      ;;
  esac
}

# Prints the shared layers that a profile loads before its own files, one per
# line. The devhost layer holds what the development machines share:
# mise.devhost.toml, configs/mise/config/config.devhost.toml, and the devhost
# app lists in apps/. The name is unusual on purpose: mise loads the
# mise.<env>.toml of every project folder too, and projects often use dev.
dotfiles_profile_layers() {
  case "${1:-}" in
    air) ;;
    *) printf 'devhost\n' ;;
  esac
}

# Prints the mise environments of a profile, comma separated: the layers, then
# the profile. A later environment wins, so the profile file overrides a layer.
dotfiles_profile_mise_env() {
  local layer envs=""
  for layer in $(dotfiles_profile_layers "${1:-}"); do
    envs="${envs}${layer},"
  done
  printf '%s%s\n' "$envs" "${1:-}"
}

# Prints the env line that .miserc.local.toml holds for a profile.
dotfiles_profile_miserc_line() {
  local env line="" IFS=,
  for env in $(dotfiles_profile_mise_env "${1:-}"); do
    line="${line:+$line, }\"$env\""
  done
  printf 'env = [%s]\n' "$line"
}

# Prints the app lists of one kind for a profile: the list for every Mac, the
# list of each layer, then the profile's own list. A missing list is skipped.
# KIND is brewfile or manifest.
dotfiles_profile_app_lists() {
  local root="$1" profile="$2" kind="$3" name list
  case "$kind" in
    brewfile) printf '%s\n' "$root/Brewfile" ;;
    manifest) printf '%s\n' "$root/apps/manifest.tsv" ;;
    *) return 2 ;;
  esac
  for name in $(dotfiles_profile_layers "$profile") "$profile"; do
    case "$kind" in
      brewfile) list="$root/apps/$name.Brewfile" ;;
      manifest) list="$root/apps/manifest.$name.tsv" ;;
    esac
    [[ ! -f "$list" ]] || printf '%s\n' "$list"
  done
}

# Prints the backup groups that setup restores on a profile. The Mac mini has
# no Synology Drive and no Mackup, so it restores only the Raycast export. The
# Air starts fresh and restores nothing.
dotfiles_profile_restores() {
  case "${1:-}" in
    macmini) printf 'raycast\n' ;;
    air) ;;
    *) printf 'mackup raycast codex\n' ;;
  esac
}

# Prints the profile. DOTFILES_PROFILE wins, then the last name of the env list
# in the ignored .miserc.local.toml. A Linux container without either uses container.
dotfiles_profile() {
  local root="${1:-}" profile="${DOTFILES_PROFILE:-}" saved line system
  # The last name in the list is the profile. The names before it are layers.
  local pattern='^[[:space:]]*env[[:space:]]*=[[:space:]]*\[[[:space:]]*("[a-z/-]+"[[:space:]]*,[[:space:]]*)*"([a-z/-]+)"[[:space:]]*,?[[:space:]]*\][[:space:]]*$'
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
        profile="${BASH_REMATCH[2]}"
      fi
    done <"$saved"
    [[ -n "$profile" ]] || {
      printf 'dotfiles: .miserc.local.toml has no profile. Add a line such as env = ["macowl"].\n' >&2
      return 2
    }
  fi
  if [[ -z "$profile" ]]; then
    if [[ "$system" == Linux && (-f /.dockerenv || -f /run/.containerenv) ]]; then
      profile=container
    else
      printf 'dotfiles: select a profile. Save env = ["macowl"] in %s, or set DOTFILES_PROFILE.\n' "$saved" >&2
      return 2
    fi
  fi
  profile="$(dotfiles_profile_normalize "$profile")" || return
  dotfiles_profile_validate "$profile" "$system" || return
  printf '%s\n' "$profile"
}
