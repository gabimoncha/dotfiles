# Quickstart

## Fresh Mac

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

`./bin/setup` runs preflight, bootstrap, and app installation first. After unattended work finishes, it offers to continue into interactive auth, Mackup restore, and Raycast restore steps. Rerun it later when Apple ID, App Store, iCloud, or MAS prerequisites become ready.

If setup opens the Xcode Command Line Tools installer popup, finish that installer and rerun `./bin/setup`.

The lower-level commands still exist for targeted reruns:

```bash
./bin/preflight
./bin/bootstrap
./bin/install-apps
./bin/auth-setup
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
