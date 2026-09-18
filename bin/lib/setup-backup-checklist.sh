#!/usr/bin/env bash

setup_backup_location() {
  local path="$1" pattern="$2" file flags total=0 pending=0 unreadable=0
  printf '  %s\n' "$path"
  if [[ ! -d "$path" ]]; then
    printf '    Not visible. Check cloud sign-in and sync, or create a backup on the old Mac.\n'
    return
  fi
  if [[ ! -r "$path" || ! -x "$path" ]]; then
    printf '    Cannot inspect this folder. Check access permissions.\n'
    return
  fi
  while IFS= read -r -d '' file; do
    total=$((total + 1))
    flags="$(stat -f '%Sf' "$file" 2>/dev/null)" || flags=unknown
    if [[ "$flags" == *dataless* || "$flags" == *offline* ]]; then
      pending=$((pending + 1))
    elif [[ "$flags" == unknown || ! -r "$file" ]]; then
      unreadable=$((unreadable + 1))
    fi
  done < <(find "$path" -type f -name "$pattern" ! -name .DS_Store -print0 2>/dev/null)
  if [[ "$total" == 0 ]]; then
    printf '    No matching backup files visible (%s). Check sync or the old Mac backup.\n' "$pattern"
  else
    printf '    %s files visible; %s need download; %s unreadable or unknown.\n' "$total" "$pending" "$unreadable"
  fi
}

setup_backup_checklist() {
  local primary="${HOME}/Library/CloudStorage/SynologyDrive-personal/MacBackups"
  local secondary="${HOME}/Library/Mobile Documents/com~apple~CloudDocs"
  local kind pattern
  cat <<'EOF'

Cloud backups needed for restore
Setup restores three backup groups: Mackup, Raycast, and Codex.
Synology Drive is primary; iCloud Drive is the fallback. Only one copy is needed.
This check reads file metadata only. It does not download or restore files.
EOF
  for kind in Mackup Raycast Codex; do
    case "$kind" in
      Mackup) pattern='*'; printf '\nMackup: download the entire folder (includes Cursor and other allowlisted app settings).\n' ;;
      Raycast) pattern='*.rayconfig'; printf '\nRaycast: download the newest .rayconfig export; import it in Raycast with its password.\n' ;;
      Codex) pattern='codex-state-*.tar.gz.age'; printf '\nCodex: download codex-state-latest.tar.gz.age, or the newest dated archive; its passphrase is required.\n' ;;
    esac
    setup_backup_location "$primary/$kind" "$pattern"
    setup_backup_location "$secondary/$kind" "$pattern"
  done
  cat <<'EOF'

In Finder, open iCloud Drive and download Mackup, the Raycast export, and the
Codex archive listed above. You can instead use the Synology Drive copies.
If Raycast was exported elsewhere in iCloud Drive, download that .rayconfig;
the restore step also searches iCloud Drive for exports outside Raycast/.
Wait for downloads to finish, then continue setup or rerun it.
Visible files do not prove that a backup is complete or valid. Missing folders
do not prove that backups were never saved. Check cloud sign-in and sync first.
Downloaded backups still require restore; Raycast needs a manual GUI import,
and existing Codex state is preserved for comparison. App sign-ins are separate.
EOF
}
