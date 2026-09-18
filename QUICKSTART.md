# Quickstart

## Fresh Mac

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
# Download the cloud backups listed by setup (iCloud Drive or Synology Drive).
# Review App Management permissions, then fully quit and reopen your terminal.
# Return to this directory:
./bin/setup --continue
```

`./bin/setup` runs preflight, starts Homebrew and mise foundations concurrently,
acquires gh in isolation, and installs standalone Codex CLI and Cursor Agent.
It then exits at a manual App Management permission/restart checkpoint.
`./bin/setup --continue` rechecks foundations and starts API authentication and
the remaining installation. Its dependency planner
blocks consumers of failed prerequisites while continuing independent work.
Eligible Mackup, Raycast and encrypted Codex restores require working tools,
hydrated backups and confirmation.
Rerun `./bin/setup --continue` later when Apple ID, App Store, iCloud, Synology Drive, or MAS
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

Verified GitHub API access gates bulk mise installation; SSH readiness is
reported separately. `./bin/auth-setup --api-only`, `--ssh-only` and
`--verify-mise` allow targeted repairs. `bin/bootstrap` shares the setup planner.

Every run, including `--dry-run`, prints persistent private logs under
`.local/setup-runs/<run-id>/`. Dry-run executes only preflight probes and records
provisioning as planned. See `summary.txt` and `events.jsonl` for recovery.

## Re-run Safety

The scripts are intended to be safe to rerun. Existing managed files are backed up by `bin/link-dotfiles`, Homebrew uses `--no-upgrade`, app installs skip existing bundles, Codex, Cursor Agent, and `mise` keep their standalone installer paths, and macOS defaults are gated by `~/.macos-defaults-applied`.

## Manual Finish

Some setup still needs account login or OS permissions:

- Apple ID, App Store, and iCloud
- GitHub, Cursor, Notion, Synology Drive, superwhisper
- Accessibility / Automation / Microphone permissions
- First-run setup for Xcode, Android Studio, OrbStack, and DaVinci Resolve
- Android Studio SDK setup for React Native: Android 15 SDK Platform 35,
  Sources for Android 35, Android SDK Build-Tools, Android Emulator, and at
  least one virtual device

The full mobile dev stack is part of the continuation phase by default. Use
`./bin/setup --continue --skip-mobile-dev` for a smaller run. Use
`./bin/install-mobile-dev` to rerun only the Xcode, Android Studio,
`idb-companion`, and `sourcekitten` installation.

If Ghostty, tmux plugins, or Raycast hotkeys do not look restored after setup, run `./bin/app-state-doctor` for the concrete missing piece.

Personal skills require a reviewed source commit and installed reviewed skills
CLI; otherwise they are deferred. See [security and manual validation](SETUP-SECURITY.md).
