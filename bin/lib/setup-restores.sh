#!/usr/bin/env bash

newest_file() {
  local dir="$1"
  local pattern="$2"
  local exclude="${3:-}"
  local selected=0 candidate

  [[ -d "$dir" ]] || return 0

  if [[ -n "$exclude" ]]; then
    find "$dir" -type f -name "$pattern" ! -name "$exclude" -exec stat -f '%m %N' {} \; 2>/dev/null | sort -nr | sed 's/^[0-9][0-9]* //g' | while IFS= read -r candidate; do if [[ "${selected:-0}" == 0 ]] && restore_hydrated_file "$candidate"; then printf '%s\n' "$candidate"; selected=1; fi; done
  else
    find "$dir" -type f -name "$pattern" -exec stat -f '%m %N' {} \; 2>/dev/null | sort -nr | sed 's/^[0-9][0-9]* //g' | while IFS= read -r candidate; do if [[ "${selected:-0}" == 0 ]] && restore_hydrated_file "$candidate"; then printf '%s\n' "$candidate"; selected=1; fi; done
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

codex_portable_state_exists() {
  [[ -e "${HOME}/.codex/config.toml" ]] ||
    [[ -e "${HOME}/.codex/keybindings.json" ]] ||
    [[ -e "${HOME}/.codex/AGENTS.md" ]] ||
    [[ -d "${HOME}/.codex/rules" ]] ||
    [[ -d "${HOME}/.codex/memories" ]] ||
    [[ -d "${HOME}/.codex/automations" ]]
}


. "${repo_root}/bin/lib/restore-readiness.sh"

setup_real_tool() {
  local tool="$1" candidate
  if [[ -x "${HOME}/.local/bin/mise" ]]; then
    candidate="$(MISE_AUTO_INSTALL=0 "${HOME}/.local/bin/mise" which "$tool" 2>/dev/null)" || candidate=""
    case "$candidate" in */shims/*) candidate="" ;; esac
    if [[ -n "$candidate" && -x "$candidate" ]]; then printf '%s\n' "$candidate"; return; fi
  fi
  candidate="$(command -v "$tool" 2>/dev/null)" || return 1
  case "$candidate" in /*/shims/*|*/home/bin/gh|"$HOME/bin/gh") return 1 ;; esac
  [[ "$candidate" == /* && -x "$candidate" ]] || return 1
  printf '%s\n' "$candidate"
}

restore_offer() {
  local kind="$1" response status=0
  shift
  if [[ ! -t 0 ]]; then
    runtime_record_deferred "restore.$kind" "eligible; needs interactive confirmation" "Run ./bin/file-restore $kind in a terminal."
    return 0
  fi
  printf 'Review executable configs, extensions, skills and automations before restoring.\nRestore %s now? [y/N] ' "$kind"
  read -r response || response=n
  case "$response" in y|Y|yes|YES) ;; *) runtime_record_deferred "restore.$kind" "declined"; return 0 ;; esac
  "${repo_root}/bin/file-restore" "$kind" "$@" || status=$?
  if [[ "$status" != 0 ]]; then
    runtime_record_failure recoverable "restore.$kind" "restore failed" "" "Review the archive and retry explicitly."
    return "$status"
  elif [[ "$kind" == raycast ]]; then
    runtime_record_deferred restore.raycast "GUI import opened; manual completion pending"
  else
    runtime_record_completed "restore.$kind"
  fi
}

setup_restores() {
  local tool backup="" candidate archive status=0
  for candidate in "${HOME}/Library/CloudStorage/SynologyDrive-personal/MacBackups/Mackup" "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Mackup"; do
    if restore_hydrated_tree "$candidate"; then backup="$candidate"; break; fi
  done
  if tool="$(setup_real_tool mackup)" && "$tool" --version >/dev/null 2>&1 && [[ -n "$backup" ]]; then
    PATH="$(dirname "$tool"):$PATH" restore_offer mackup || status=1
  else runtime_record_deferred restore.mackup "requires working mackup and a readable, hydrated backup"; fi

  archive="$(latest_rayconfig || true)"
  if [[ -d "${DOTFILES_APPLICATIONS_DIR:-/Applications}/Raycast.app" ]] && restore_hydrated_file "$archive"; then
    restore_offer raycast "$archive" || status=1
  else runtime_record_deferred restore.raycast "requires Raycast and a readable, hydrated export"; fi

  archive="$(latest_codex_state_archive || true)"
  if tool="$(setup_real_tool age)" && "$tool" --version >/dev/null 2>&1 && restore_hydrated_file "$archive"; then
    if codex_portable_state_exists; then
      runtime_record_deferred restore.codex "existing portable state preserved; compare with file-restore codex --dry-run first"
    else
      # file-restore decrypts and validates the archive allowlist before copying.
      PATH="$(dirname "$tool"):$PATH" restore_offer codex "$archive" || status=1
    fi
  else runtime_record_deferred restore.codex "requires working age and a readable, hydrated encrypted archive"; fi
  return "$status"
}
