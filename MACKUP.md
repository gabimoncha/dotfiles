# Mackup

Mackup is installed by mise and configured through `home/.mackup.cfg`.

The config uses Synology Drive file-system storage and a small app allowlist.
The helper scripts mirror successful Synology backups to iCloud on a
best-effort basis when iCloud is ready. Do not remove the allowlist unless you
have reviewed every app Mackup would sync; broad sync can capture noisy or
private app state.

Custom Mackup application definitions live under `home/.config/mackup/applications/` and are linked into `~/.config/mackup/applications/` by `bin/link-dotfiles`.

Do not add apps whose settings are already tracked under `home/`. AeroSpace and Ghostty are intentionally direct repo-owned symlinks. VS Code and Cursor are intentionally owned by Mackup instead of direct repo symlinks, because Mackup supports their user settings, keybindings, prompts, and snippets.

OBS is managed with Mackup's built-in `obs` definition. It backs up the core OBS
preferences, `global.ini`, and `basic` profiles/scenes; it does not manage
plugins, logs, profiler data, or update caches.

Raycast is not managed by Mackup here. Restore it from an encrypted
`.rayconfig` export saved outside git, preferably under
`SynologyDrive-personal/MacBackups/Raycast` and mirrored to
`iCloud Drive/Raycast`. Use the exact timestamped save path printed by the
helper, which uses this filename pattern:

```text
raycast-settings-YYYYMMDD-HHMMSS.rayconfig
```

Run:

```bash
./bin/file-backup raycast
./bin/file-restore raycast
```

Codex memories are not managed by Mackup. Codex mixes durable config with auth,
sessions, sqlite state, plugin caches, worktrees, and private generated memory,
so this repo uses a separate passphrase-encrypted archive workflow instead:

```bash
./bin/file-backup codex
./bin/file-restore codex
```

Use copy-mode commands only:

```bash
./bin/file-backup mackup
./bin/file-restore mackup
```

When replacing existing backup copies with the current machine state, pass
Mackup options through the helper. The combined backup accepts Mackup options:

```bash
./bin/file-backup --force
```

For only Mackup:

```bash
./bin/file-backup mackup --force
```

The older `bin/mackup-backup`, `bin/mackup-restore`, `bin/raycast-*`, and
`bin/codex-*` commands remain as compatibility aliases to `bin/file-backup` and
`bin/file-restore`.

Do not use Mackup link mode on modern macOS. Upstream warns that symlinked preferences can break on macOS Sonoma and later, so this repo treats Mackup as an explicit backup/restore tool.

Set up Synology Drive before running the file backup helper when possible. It
reads the tracked `home/.mackup.cfg`, expects the Synology file-system target,
and falls back to iCloud restore when the Synology backup is not available yet.
If neither sync provider is ready, it defers cleanly.

Restore selection is intentionally simple:

- Mackup has one current backup tree, not timestamped snapshots in this repo.
  Older copies depend on Synology Drive or iCloud file history.
- Raycast restores the newest `.rayconfig` by modification time, preferring
  Synology over iCloud. You can pass an explicit `.rayconfig` path to restore a
  different export.
- Codex restores `codex-state-latest.tar.gz.age` first, falling back to the
  newest timestamped archive. You can pass an explicit archive path to restore
  an older Codex archive.

If Mackup reports a conflict with a file already managed by this repo, keep this repo as the source of truth and remove that app from `home/.mackup.cfg`.
