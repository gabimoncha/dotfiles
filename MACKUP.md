# Mackup

Mackup is installed by Homebrew and configured through `home/.mackup.cfg`.

The config uses iCloud storage and a small app allowlist. Do not remove the allowlist unless you have reviewed every app Mackup would sync; broad sync can capture noisy or private app state.

Do not add apps whose settings are already tracked under `home/`. AeroSpace and Ghostty are intentionally direct repo-owned symlinks. VS Code and Cursor are intentionally owned by Mackup instead of direct repo symlinks, because Mackup supports their user settings, keybindings, prompts, and snippets.

Raycast is not managed by Mackup here. Restore it from an encrypted `.rayconfig` export saved outside git, preferably in `iCloud Drive/Raycast`, with:

```bash
./bin/raycast-backup
./bin/raycast-restore
```

Use copy-mode commands only:

```bash
./bin/mackup-backup
./bin/mackup-restore
```

Do not use Mackup link mode on modern macOS. Upstream warns that symlinked preferences can break on macOS Sonoma and later, so this repo treats Mackup as an explicit backup/restore tool.

Set up iCloud Drive before running either helper. The helpers read the tracked `home/.mackup.cfg`, expect `engine = icloud`, and defer cleanly if iCloud Drive is not available yet.

If Mackup reports a conflict with a file already managed by this repo, keep this repo as the source of truth and remove that app from `home/.mackup.cfg`.
