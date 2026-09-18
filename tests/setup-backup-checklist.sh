#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home"
mkdir -p "$HOME" "$fixture/bin"
. "$repo_root/bin/lib/setup-backup-checklist.sh"
setup_backup_checklist > "$fixture/missing"
for kind in Mackup Raycast Codex; do
  grep -q "/$kind" "$fixture/missing"
done
grep -q 'Not visible' "$fixture/missing"
backup="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Mackup"
mkdir -p "$backup"
printf 'settings' > "$backup/settings.json"
touch "$backup/empty.yml"
setup_backup_checklist > "$fixture/local"
grep -q '2 files visible; 0 need download; 0 unreadable or unknown' "$fixture/local"
cat > "$fixture/bin/stat" <<'STAT'
#!/bin/bash
printf dataless
STAT
chmod +x "$fixture/bin/stat"
PATH="$fixture/bin:$PATH" setup_backup_checklist > "$fixture/cloud"
grep -q '2 files visible; 2 need download' "$fixture/cloud"
grep -q 'does not download or restore' "$fixture/cloud"
grep -q 'Only one copy is needed' "$fixture/cloud"
bash "$repo_root/bin/obs-permissions" > "$fixture/obs"
for setting in 'Screen & System Audio Recording' Camera Microphone 'Input Monitoring'; do
  grep -Fq "$setting: OBS = on" "$fixture/obs"
done
printf 'PASS: backup checklist missing, local, empty, and cloud placeholder files\n'
