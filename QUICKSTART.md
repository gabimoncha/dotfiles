# Quickstart

## Fresh Mac

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

`./bin/setup` runs preflight, bootstrap, and app installation first. After unattended work finishes, it offers to continue into interactive auth, Mackup restore, Raycast restore, and encrypted Codex state restore steps. Rerun it later when Apple ID, App Store, iCloud, or MAS prerequisites become ready.

If setup opens the Xcode Command Line Tools installer popup, finish that installer and rerun `./bin/setup`.

The lower-level commands still exist for targeted reruns:

```bash
./bin/preflight
./bin/bootstrap
./bin/install-apps
./bin/install-mobile-dev
./bin/auth-setup
./bin/codex-backup
./bin/codex-restore
./bin/setup-tmux
./bin/app-state-doctor
```

GitHub SSH is configured after bootstrap with `./bin/auth-setup`.

## Re-run Safety

The scripts are intended to be safe to rerun. Existing managed files are backed up by `bin/link-dotfiles`, Homebrew uses `--no-upgrade`, app installs skip existing bundles, and macOS defaults are gated by `~/.macos-defaults-applied`.

## Manual Finish

Some setup still needs account login or OS permissions:

- Apple ID, App Store, and iCloud
- GitHub, Cursor, VS Code, Notion, Synology Drive, superwhisper
- Accessibility / Automation / Microphone permissions
- First-run setup for Xcode, Android Studio, OrbStack, and DaVinci Resolve
- Android Studio SDK setup for React Native: Android 15 SDK Platform 35,
  Sources for Android 35, Android SDK Build-Tools, Android Emulator, and at
  least one virtual device

The full mobile dev stack is intentionally outside `./bin/setup` because Xcode
and Android Studio are large downloads. Run `./bin/install-mobile-dev` when you
want full Xcode, Android Studio, `idb-companion`, and `sourcekitten`.

If Ghostty, tmux plugins, or Raycast hotkeys do not look restored after setup, run `./bin/app-state-doctor` for the concrete missing piece.
