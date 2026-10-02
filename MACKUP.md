# Backup and restore

Use `bin/file-backup` and `bin/file-restore` for portable state. They handle
Mackup app settings, encrypted Raycast exports, and encrypted Codex archives.
The older `mackup-*`, `raycast-*`, and `codex-*` scripts are compatibility aliases.

## Storage and prerequisites

The primary root is
`~/Library/CloudStorage/SynologyDrive-personal/MacBackups`.
The secondary root is `~/Library/Mobile Documents/com~apple~CloudDocs`.
Each has `Mackup`, `Raycast`, and `Codex` subdirectories.

Sign in and configure cloud sync first. A Finder NAS mount under `/Volumes`
is not a local Synology Drive sync folder. Restore requires readable,
downloaded files; visible cloud placeholders are not sufficient. Download one
provider's backup in Finder before restoring.

```bash
./bin/file-restore --debug
```

This reports expected roots, visible Synology sync folders, and mounted NAS
paths. If the backup exists only on the NAS, repair the Synology Drive sync task.
**Confirm actual sync before relying on a backup:** current Raycast backup can
create ordinary local provider directories, and the combined backup can exit
zero when neither provider is available.

## Combined commands

```bash
./bin/file-backup
./bin/file-restore
```

Backup runs Mackup, then Codex, then Raycast's manual export handoff. Rerun
`./bin/file-backup raycast` after saving the export to mirror it to iCloud.
Restore runs Mackup, opens Raycast import, and offers Codex restore interactively.
Passwords and GUI completion remain manual. Top-level options such as `--force`
are passed to Mackup; use component commands for other options.

## Mackup settings

Mise installs Mackup. [home/.mackup.cfg](home/.mackup.cfg) is the allowlist and
storage configuration. Use explicit copy-mode backup/restore; do not use link
mode or add apps whose files this repository already links.

```bash
./bin/file-backup mackup
./bin/file-restore mackup
./bin/file-backup mackup --force
./bin/file-restore mackup --force
```

Cursor settings belong here; AeroSpace and Ghostty belong to the repository.
OBS uses Mackup's built-in profile for preferences, profiles and scenes, not
plugins, logs or caches. VS Code is not in the current inventory.

Successful Synology backups are mirrored to iCloud when available. Restore
selects a hydrated Synology tree, then iCloud. Mackup has one current tree;
older copies depend on provider file history. If Mackup conflicts with a
repo-managed file, keep the repo as owner and remove the conflicting app from
the allowlist. Optional custom definitions are linked if their source exists
under `home/.config/mackup/applications/`.

## Raycast

```bash
./bin/file-backup raycast
./bin/file-restore raycast
./bin/file-restore raycast /path/to/export.rayconfig
```

The backup helper prints a timestamped `raycast-settings-*.rayconfig` save path
and opens Raycast. Export there, then rerun the helper to mirror the file.
Restore selects the newest hydrated export by modification time: Synology,
then iCloud's Raycast folder, then the broader iCloud tree. An explicit path
selects a different export. Keep exports and passwords out of Git.
Opening the import dialog is not proof that the import completed.

## Codex

```bash
./bin/file-backup codex
./bin/file-backup codex --output-dir /path/to/private-backups
./bin/file-restore codex --dry-run
./bin/file-restore codex
./bin/file-restore codex --replace /path/to/codex-state.tar.gz.age
```

`age -p` encrypts the allowlisted config, keybindings, instructions, rules,
memories and automation definitions. Authentication, sessions, databases,
worktrees, plugins, global app/workspace state and installer packages are
excluded. Global skills are installed separately from reviewed sources.

Selection prefers Synology's `codex-state-latest.tar.gz.age`, then its newest
dated archive, then the equivalent iCloud choices. Pass a path for another
archive. Restore decrypts to private temporary storage and validates archive
paths. Dry-run still needs decryption but does not modify destination files.

Default restore copies missing files, skips identical files, and stages incoming
conflicts under `~/.dotfiles-backups/<timestamp>/codex-state/incoming`.
`--replace` first saves current files under the sibling `current` directory.
Setup defers Codex restore when portable state already exists; compare it first.
Review executable settings and automations before restoring after a compromise.
