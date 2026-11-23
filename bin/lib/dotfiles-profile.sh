#!/usr/bin/env bash
# The machine's role selects its mise.<role>.toml file at the repository root:
# mainhost and lightshell on macOS, devstation on macOS or Linux, and
# container, a devstation in a Linux container. A macOS role can also have app
# lists in apps/. The scripts call the role the profile. What one machine needs
# alone is in its fleet host folder. Bash 3.2 compatible.

# Accept the names that older versions of this repository used.
dotfiles_profile_normalize() {
  case "${1:-}" in
    macos/pro | pro | macowl) printf 'mainhost\n' ;;
    macmini) printf 'devstation\n' ;;
    macos/air | air) printf 'lightshell\n' ;;
    linux/container | linux-container) printf 'container\n' ;;
    *) printf '%s\n' "${1:-}" ;;
  esac
}

# Callers run this check before they change machine state.
dotfiles_profile_validate() {
  local profile="${1:-}" system="${2:-$(uname -s)}"
  case "$profile" in
    mainhost | lightshell)
      [[ "$system" == Darwin ]] || {
        printf 'dotfiles: role %s requires macOS.\n' "$profile" >&2
        return 2
      }
      ;;
    devstation) ;;
    container)
      [[ "$system" == Linux ]] || {
        printf 'dotfiles: role %s requires Linux.\n' "$profile" >&2
        return 2
      }
      ;;
    *)
      printf 'dotfiles: unsupported role: %s. Use mainhost, devstation, lightshell, or container.\n' "$profile" >&2
      return 2
      ;;
  esac
}

# Prints the shared layers that a role loads before its own files, one per
# line. The devhost layer holds what the development machines share:
# mise.devhost.toml, configs/mise/config/config.devhost.toml, and the devhost
# app lists in apps/. The name is unusual on purpose: mise loads the
# mise.<env>.toml of every project folder too, and projects often use dev.
# A container is a devstation, so it loads that role first.
dotfiles_profile_layers() {
  case "${1:-}" in
    lightshell) ;;
    container) printf 'devhost\ndevstation\n' ;;
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
  local env envs line=""
  # Get the list before IFS changes. A called function sees this local IFS,
  # and the layer loop in dotfiles_profile_mise_env splits on newlines.
  envs="$(dotfiles_profile_mise_env "${1:-}")" || return
  local IFS=,
  for env in $envs; do
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

# Prints the backup groups that setup restores for a role. A devstation has no
# Synology Drive and no Mackup, so it restores only the Raycast export. The
# Air starts fresh and restores nothing.
dotfiles_profile_restores() {
  case "${1:-}" in
    devstation) printf 'raycast\n' ;;
    lightshell) ;;
    *) printf 'mackup raycast codex\n' ;;
  esac
}

# Prints the role. DOTFILES_PROFILE wins, then the last name of the env list
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
      # Only a root key selects the profile. A table such as [env_sets] ends it.
      [[ ! "$line" =~ ^[[:space:]]*\[ ]] || break
      if [[ "$line" =~ $pattern ]]; then
        profile="${BASH_REMATCH[2]}"
      fi
    done <"$saved"
    [[ -n "$profile" ]] || {
      printf 'dotfiles: .miserc.local.toml has no role. Add a line such as env = ["mainhost"].\n' >&2
      return 2
    }
  fi
  if [[ -z "$profile" ]]; then
    if [[ "$system" == Linux && (-f /.dockerenv || -f /run/.containerenv) ]]; then
      profile=container
    else
      local example=mainhost
      [[ "$system" != Linux ]] || example=devstation
      printf 'dotfiles: select a role. Save env = ["%s"] in %s, or set DOTFILES_PROFILE.\n' "$example" "$saved" >&2
      return 2
    fi
  fi
  profile="$(dotfiles_profile_normalize "$profile")" || return
  dotfiles_profile_validate "$profile" "$system" || return
  printf '%s\n' "$profile"
}
