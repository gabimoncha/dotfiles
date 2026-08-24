# Quickstart

## Fresh Mac

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

`./bin/setup` runs preflight, ensures GitHub CLI authentication for mise, then
runs bootstrap and app installation. After unattended work finishes, it offers
to continue into Mackup, Raycast, and encrypted Codex state restore steps.
Rerun it later when Apple ID, App Store, iCloud, Synology Drive, or MAS
prerequisites become ready.

Preflight first checks the active Apple or MDM software update catalog. If a
macOS update is available, or if setup cannot determine the update status, open
System Settings > General > Software Update. Install the public update, restart
the Mac if required, then rerun `./bin/setup`. Setup does not install the update
or change Beta Updates.

If setup opens the Xcode Command Line Tools installer popup, finish that installer and rerun `./bin/setup`.

The lower-level commands still exist for targeted reruns:

```bash
./bin/preflight
./bin/bootstrap
./bin/ensure-codex-standalone
./bin/ensure-cursor-agent-standalone
./bin/ensure-mise-standalone
./bin/install-apps
./bin/install-mobile-dev
./bin/auth-setup
./bin/file-backup
./bin/file-restore
./bin/setup-tmux
./bin/app-state-doctor
```

GitHub CLI, mise token access, and GitHub SSH are configured before bootstrap's
bulk tool installation. Rerun `./bin/auth-setup` for a targeted repair.

## Re-run Safety

The scripts are intended to be safe to rerun. Existing managed files are backed up by `bin/link-dotfiles`, Homebrew uses `--no-upgrade`, app installs skip existing bundles, Codex, Cursor Agent, and `mise` keep their standalone installer paths, and macOS defaults are gated by `~/.macos-defaults-applied`.

## Manual Finish

Some setup still needs account login or OS permissions:

- Apple ID, App Store, and iCloud
- GitHub, Cursor, VS Code, Notion, Synology Drive, superwhisper
- Accessibility / Automation / Microphone permissions
- First-run setup for Xcode, Android Studio, OrbStack, and DaVinci Resolve
- Android Studio SDK setup for React Native: Android 15 SDK Platform 35,
  Sources for Android 35, Android SDK Build-Tools, Android Emulator, and at
  least one virtual device

The full mobile dev stack is part of `./bin/setup` by default. Use
`./bin/setup --skip-mobile-dev` for a smaller run. Use
`./bin/install-mobile-dev` to rerun only the Xcode, Android Studio,
`idb-companion`, and `sourcekitten` installation.

If Ghostty, tmux plugins, or Raycast hotkeys do not look restored after setup, run `./bin/app-state-doctor` for the concrete missing piece.
