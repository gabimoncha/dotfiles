#!/usr/bin/env bash
# Shared backup selection: hydrated Synology copies first, then iCloud.
. "${repo_root}/bin/lib/restore-readiness.sh"

newest_file() {
  local dir="$1"
  local pattern="$2"
  local exclude="${3:-}"
  local selected=0 candidate

  [[ -d "$dir" ]] || return 0

  if [[ -n "$exclude" ]]; then
    find "$dir" -type f -name "$pattern" ! -name "$exclude" -exec stat -f '%m %N' {} \; 2>/dev/null |
      sort -nr | sed 's/^[0-9][0-9]* //g' |
      while IFS= read -r candidate; do
        if [[ "${selected:-0}" == 0 ]] && restore_hydrated_file "$candidate"; then
          printf '%s\n' "$candidate"
          selected=1
        fi
      done
  else
    find "$dir" -type f -name "$pattern" -exec stat -f '%m %N' {} \; 2>/dev/null |
      sort -nr | sed 's/^[0-9][0-9]* //g' |
      while IFS= read -r candidate; do
        if [[ "${selected:-0}" == 0 ]] && restore_hydrated_file "$candidate"; then
          printf '%s\n' "$candidate"
          selected=1
        fi
      done
  fi
}

latest_rayconfig() {
  local icloud_dir="${HOME}/Library/Mobile Documents/com~apple~CloudDocs"
  local synology_dir="${HOME}/Library/CloudStorage/SynologyDrive-personal/MacBackups/Raycast"
  local raycast_dir="${icloud_dir}/Raycast"
  local rayconfig

  if [[ -d "$synology_dir" ]]; then
    rayconfig="$(newest_file "$synology_dir" '*.rayconfig')"
    if [[ -n "$rayconfig" ]]; then
      printf '%s\n' "$rayconfig"
      return 0
    fi
  fi

  if [[ -d "$raycast_dir" ]]; then
    rayconfig="$(newest_file "$raycast_dir" '*.rayconfig')"
    if [[ -n "$rayconfig" ]]; then
      printf '%s\n' "$rayconfig"
      return 0
    fi
  fi

  if [[ -d "$icloud_dir" ]]; then
    newest_file "$icloud_dir" '*.rayconfig'
  fi
}

latest_codex_state_archive() {
  local synology_archive="${HOME}/Library/CloudStorage/SynologyDrive-personal/MacBackups/Codex/codex-state-latest.tar.gz.age"
  local icloud_archive="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Codex/codex-state-latest.tar.gz.age"
  local archive

  if restore_hydrated_file "$synology_archive"; then
    printf '%s\n' "$synology_archive"
    return 0
  fi

  archive="$(newest_file "${HOME}/Library/CloudStorage/SynologyDrive-personal/MacBackups/Codex" 'codex-state-*.tar.gz.age' 'codex-state-latest.tar.gz.age')"
  if [[ -n "$archive" ]]; then
    printf '%s\n' "$archive"
    return 0
  fi

  if restore_hydrated_file "$icloud_archive"; then
    printf '%s\n' "$icloud_archive"
    return 0
  fi

  newest_file "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Codex" 'codex-state-*.tar.gz.age' 'codex-state-latest.tar.gz.age'
}
