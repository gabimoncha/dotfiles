#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home" TMPDIR="$fixture" DOTFILES_APPLICATIONS_DIR="$fixture/Applications"
mkdir -p "$HOME" "$fixture/bin" "$DOTFILES_APPLICATIONS_DIR"
export PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
. "$repo_root/bin/lib/setup-restores.sh"
records="$fixture/records"
runtime_record_deferred() { printf 'deferred %s %s\n' "$1" "${2:-}" >> "$records"; }
runtime_record_completed() { printf 'completed %s\n' "$1" >> "$records"; }
runtime_record_failure() { printf 'failed %s\n' "$2" >> "$records"; }
setup_restores </dev/null
[[ "$(wc -l < "$records" | tr -d ' ')" == 3 ]]
! grep -q completed "$records"
printf '#!/bin/bash\nexit 0\n' > "$fixture/bin/mackup"
chmod +x "$fixture/bin/mackup"
status=0
"$repo_root/bin/file-restore" mackup >/dev/null 2>&1 || status=$?
[[ "$status" == 20 ]]
backup="$HOME/Library/CloudStorage/SynologyDrive-personal/MacBackups/Mackup"
mkdir -p "$backup"
! restore_hydrated_tree "$backup"
printf 'fixture' > "$backup/settings"
: > "$backup/empty"
! restore_hydrated_file "$backup/empty"
restore_hydrated_tree "$backup"
# Simulate a cloud placeholder without touching real cloud data.
printf '#!/bin/bash\nprintf dataless\n' > "$fixture/bin/stat"
chmod +x "$fixture/bin/stat"
! restore_hydrated_tree "$backup"
rm "$fixture/bin/stat"
primary="$HOME/Library/CloudStorage/SynologyDrive-personal/MacBackups/Codex/codex-state-latest.tar.gz.age"
secondary="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Codex/codex-state-latest.tar.gz.age"
mkdir -p "$(dirname "$primary")" "$(dirname "$secondary")"
printf placeholder > "$primary"
printf hydrated > "$secondary"
cat > "$fixture/bin/stat" <<'STAT'
#!/bin/bash
if [[ "$2" == %Sf && "$3" == *SynologyDrive* ]]; then printf dataless; else /usr/bin/stat "$@"; fi
STAT
chmod +x "$fixture/bin/stat"
[[ "$(latest_codex_state_archive)" == "$secondary" ]]
rm "$fixture/bin/stat"


# Mock decryption only; exercise real archive allowlist and conflict handling.
cat > "$fixture/bin/age" <<'AGE'
#!/bin/bash
if [[ "$1" == --version ]]; then printf 'age fixture\n'; exit 0; fi
[[ "$1" == -d && "$2" == -o ]] || exit 1
cp "$4" "$3"
AGE
chmod +x "$fixture/bin/age"
mkdir -p "$fixture/payload/.codex" "$HOME/.codex"
printf 'incoming fixture\n' > "$fixture/payload/.codex/config.toml"
printf 'existing fixture\n' > "$HOME/.codex/config.toml"
tar -czf "$fixture/fixture.age" -C "$fixture/payload" .codex
"$repo_root/bin/file-restore" codex "$fixture/fixture.age" >/dev/null
[[ "$(cat "$HOME/.codex/config.toml")" == 'existing fixture' ]]
find "$HOME/.dotfiles-backups" -path '*/incoming/.codex/config.toml' | grep -q .
"$repo_root/bin/file-restore" codex --dry-run --replace "$fixture/fixture.age" >/dev/null
[[ "$(cat "$HOME/.codex/config.toml")" == 'existing fixture' ]]
printf 'forbidden' > "$fixture/payload/.codex/auth.json"
tar -czf "$fixture/bad.age" -C "$fixture/payload" .codex
if "$repo_root/bin/file-restore" codex "$fixture/bad.age" >/dev/null 2>&1; then
  printf 'forbidden archive accepted\n' >&2; exit 1
fi
printf 'export' > "$fixture/export.rayconfig"
status=0
"$repo_root/bin/file-restore" raycast "$fixture/export.rayconfig" >/dev/null 2>&1 || status=$?
[[ "$status" == 20 ]]
mkdir -p "$DOTFILES_APPLICATIONS_DIR/Raycast.app"
printf '#!/bin/bash\nprintf "opened\\n" >> "$HOME/open-calls"\n' > "$fixture/bin/open"
chmod +x "$fixture/bin/open"
"$repo_root/bin/file-restore" raycast "$fixture/export.rayconfig" > "$fixture/gui-output"
grep -q 'Import Settings' "$fixture/gui-output"
[[ "$(wc -l < "$HOME/open-calls" | tr -d ' ')" == 2 ]]
# Availability must check the application bundle, not only a Homebrew receipt.
. "$repo_root/bin/lib/setup-actions.sh"
(
  repo_root="$fixture/inventory"
  mkdir -p "$repo_root/apps"
  printf 'example\tcask\texample\tExampleFixture\tnote\n' > "$repo_root/apps/manifest.tsv"
  if setup_verify_apps; then printf 'missing app accepted\n' >&2; exit 1; fi
  mkdir -p "$DOTFILES_APPLICATIONS_DIR/ExampleFixture.app"
  setup_verify_apps
)
printf 'PASS: restore prerequisites, missing/empty/dataless backups, archive rejection, conflict preservation, dry-run, GUI handoff\n'
