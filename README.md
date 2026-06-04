# dotfiles

Source of truth for rebuilding my macOS development environment without
committing secrets, auth state, or machine-local noise.

The main path is intentionally simple:

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

Run `./bin/setup` without `sudo`. The scripts ask for a password only when a
specific privileged macOS or Homebrew step needs it.

## Setup Steps

### Step 1: Prepare the old Mac

Do this before moving to a new machine, or whenever you want to check whether
the repo still reflects the current Mac.

```bash
cd ~/development/dotfiles
./bin/prepare-sync
./bin/mackup-backup
./bin/raycast-backup
```

`bin/prepare-sync` is a drift report, not an auto-writer. It compares the
current Homebrew bundle, prints the current `mise` state, and saves backups
under `.sync-backups/` so changes can be made intentionally.

`bin/mackup-backup` copies the small Mackup allowlist to iCloud. Raycast is not
managed by Mackup here; `bin/raycast-backup` opens Raycast and tells you to save
an encrypted `.rayconfig` export under `iCloud Drive/Raycast`.

Commit and push any intentional repo changes before switching machines.

### Step 2: Clone on the new Mac

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

If Xcode Command Line Tools are missing, setup opens Apple's installer popup
and exits. Finish the installer, then rerun:

```bash
./bin/setup
```

### Step 3: Let setup do the unattended work

`bin/setup` is the fresh-machine entrypoint. Its runtime flow is:

```mermaid
flowchart TD
  Start["./bin/setup"] --> Root{"Running as root?"}
  Root -->|"yes"| RootExit["Exit: rerun without sudo"]
  Root -->|"no"| Preflight["bin/preflight"]

  Preflight --> DryRun{"--dry-run?"}
  DryRun -->|"yes"| DryApps["bin/install-apps --dry-run"]
  DryApps --> Summary["Print setup summary"]
  Summary --> Done["Exit"]

  DryRun -->|"no"| Bootstrap["bin/bootstrap"]

  subgraph BootstrapFlow["bin/bootstrap"]
    B1["Verify admin, Xcode CLT, Homebrew, mise"]
    B2["Configure sudo Touch ID unless skipped"]
    B3["Initialize nvim submodule"]
    B4["bin/link-dotfiles"]
    B5["Start mise install in background"]
    B6["Install Brewfile apps, mas apps, VS Code extensions"]
    B7["bin/link-dotfiles again after apps exist"]
    B8["Wait for mise and run bin/check-mise-tools"]
    B9["Install deferred Xcode formulae when possible"]
    B10["bin/setup-tmux"]
    B11["Install Oh My Zsh and Powerlevel10k"]
    B12["macos/defaults.sh unless skipped or already applied"]
    B13["bin/finder-sidebar-favorites"]
    B1 --> B2 --> B3 --> B4 --> B5 --> B6 --> B7 --> B8 --> B9 --> B10 --> B11 --> B12 --> B13
  end

  Bootstrap --> XcodeReady{"Xcode CLT ready after bootstrap?"}
  XcodeReady -->|"no"| XcodeExit["Exit: finish installer, rerun ./bin/setup"]
  XcodeReady -->|"yes"| InstallApps["bin/install-apps"]
  InstallApps --> LinkApps["bin/link-dotfiles"]
  LinkApps --> SetupSummary["Print setup summary"]
  SetupSummary --> Interactive{"Interactive terminal?"}

  Interactive -->|"no"| SkipFollowup["Skip auth and restore follow-up"]
  Interactive -->|"yes, after Enter"| Auth["bin/auth-setup"]
  Auth --> Mackup["bin/mackup-restore"]
  Mackup --> Raycast{"Raycast .rayconfig found in iCloud?"}
  Raycast -->|"yes"| RaycastRestore["bin/raycast-restore"]
  Raycast -->|"no"| RaycastDeferred["Defer Raycast restore"]
```

It is safe to rerun as Apple ID, App Store, iCloud, Xcode, or app permissions
become ready. The detailed bootstrap inventory is in
[`What Setup Actually Does`](#what-setup-actually-does).

Dry-run the install pass without changing the machine:

```bash
./bin/setup --dry-run
```

### Step 4: Finish auth and restore

At the end of setup, press Enter to continue the interactive follow-up. You can
also run the pieces directly later:

```bash
./bin/auth-setup
./bin/mackup-restore
./bin/raycast-restore
```

`bin/auth-setup` configures local Git identity, creates or reuses an Ed25519 SSH
key, authenticates GitHub CLI, uploads the SSH key when possible, and verifies
GitHub SSH.

`bin/mackup-restore` expects iCloud Drive and the tracked `home/.mackup.cfg`.
`bin/raycast-restore` opens the newest `.rayconfig` it can find under iCloud
Drive, or an explicit path passed as an argument.

`bin/finder-sidebar-favorites` creates `~/development` and `~/Screenshots`,
then adds both folders to Finder Favorites. It is run during setup and can be
rerun later if macOS privacy prompts or Finder state get in the way. The
sidebar label is `screenshots`; the folder path remains `~/Screenshots`.

### Step 5: Handle manual account and permission work

Some state cannot be safely automated:

- Apple ID, App Store, and iCloud sign-in
- Cursor, VS Code Settings Sync, Notion, Synology Drive, superwhisper, and
  DaVinci Resolve sign-in
- Accessibility, Automation, Microphone, and network permissions
- first-run setup for Xcode, Android Studio, OrbStack, and vendor-only apps

Manual/vendor apps currently live in `apps/manifest.tsv` as `manual` rows.
DaVinci Resolve and Pinokio are examples.

### Step 6: Verify app state

If the machine looks mostly set up but a few pieces feel incomplete, run:

```bash
./bin/app-state-doctor
```

It checks the app-state edges this repo can reason about: AeroSpace and Ghostty
config links, tmux plugins, Raycast install/export state, Touch ID for `sudo`,
and whether Spotlight is still holding Command-Space.

## What Setup Actually Does

`bin/bootstrap` is the lower-level installer used by `bin/setup`.

It:

1. verifies macOS, admin access, Xcode Command Line Tools, Homebrew, and `mise`
2. enables Touch ID for `sudo` through `/etc/pam.d/sudo_local` when supported
3. initializes the Neovim submodule
4. links tracked files from `home/` into `$HOME`
5. starts `mise install` in the background
6. installs Homebrew formulae, casks, App Store apps, and VS Code extensions
7. skips casks whose app bundle already exists in `/Applications`
8. defers App Store apps until `mas` and App Store sign-in are usable
9. defers Xcode-dependent formulae until full Xcode is selected
10. verifies `mise` tools with `bin/check-mise-tools`
11. removes NearDrop quarantine after install
12. installs tmux plugins through TPM
13. installs Oh My Zsh and Powerlevel10k when missing
14. applies tracked macOS defaults once

Touch ID for `sudo` can be managed directly:

```bash
./bin/configure-sudo-touch-id --check
./bin/configure-sudo-touch-id --enable
./bin/configure-sudo-touch-id --disable
```

Skip this during setup when needed:

```bash
DOTFILES_SKIP_SUDO_TOUCH_ID=1 ./bin/setup
```

Apple Watch approval depends on macOS Auto Unlock being enabled in System
Settings. This repo configures the `sudo` Touch ID PAM hook, not Apple Watch
pairing or unlock settings.

The macOS defaults can be skipped for a run:

```bash
DOTFILES_SKIP_MACOS_DEFAULTS=1 ./bin/bootstrap
```

## Ownership Model

This repo is deliberately boring about ownership:

- `Brewfile` owns Homebrew formulae, casks, taps, App Store app entries,
  and VS Code extensions.
- `home/.config/mise/config.toml` owns language runtimes and global developer
  tools that `mise` supports, including backend-prefixed tools such as
  `gem:fastlane` and `conda:aria2`.
- `apps/manifest.tsv` is the typed ledger for extra install handling.
- `home/` owns files that get symlinked into `$HOME`.
- `macos/defaults.sh` owns conservative macOS defaults.
- `nvim/` is a separate Neovim repo mounted here as a submodule.
- Mackup owns only the allowlisted app settings in `home/.mackup.cfg`.
- Raycast is restored from an encrypted `.rayconfig` export outside git.

When adding a tool, use this order:

1. Mac App Store via `mas`, if it is a GUI app available there
2. `mise`, if `mise ls-remote <tool>` or an appropriate backend-prefixed id
   supports it
3. Homebrew in `Brewfile`, if it does not belong in `mas` or `mise`
4. `apps/manifest.tsv`, if it needs special handling or is manual/vendor-only

Do not commit secrets, tokens, private emails, `.rayconfig` files, cache
databases, session state, or machine-local exports.

## Important Paths

```text
Brewfile                         Homebrew, mas, casks, VS Code extensions
apps/manifest.tsv                extra typed app/tool ledger
bin/setup                        fresh-Mac entrypoint
bin/bootstrap                    lower-level bootstrap
bin/link-dotfiles                symlink managed files into $HOME
bin/preflight                    repo and machine checks
bin/auth-setup                   Git/GitHub/SSH follow-up
bin/configure-sudo-touch-id      Touch ID for sudo PAM setup
bin/install-apps                 manifest installer
bin/finder-sidebar-favorites     add repo-owned Finder sidebar favorites
bin/app-state-doctor             post-setup app-state checks
home/                            tracked $HOME sources
home/.config/mise/config.toml    mise-owned tools
home/.mackup.cfg                 Mackup allowlist using iCloud storage
macos/defaults.sh                tracked macOS defaults
nvim/                            Neovim submodule linked to ~/.config/nvim
```

## Managed Dotfiles

`bin/link-dotfiles` links tracked files into `$HOME` and backs up replaced
targets under `~/.dotfiles-backups/<timestamp>/`.

Currently managed:

- `~/.gitconfig`
- `~/.aerospace.toml`
- `~/.zshenv`, `~/.zprofile`, `~/.zshrc`
- `~/.p10k.zsh`
- `~/.mackup.cfg`
- `~/.rgrc`
- `~/.tmux.conf`
- `~/.config/mise/config.toml`
- `~/.config/zsh/*.zsh`
- `~/.config/karabiner/karabiner.json`
- `~/.config/zed/settings.json`
- `~/.config/zed/keymap.json`
- `~/Documents/superwhisper/settings/settings.json`
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/scripts/toggle_function_keys.sh`
- `nvim/` as `~/.config/nvim`

AeroSpace and Ghostty config links are only created after their app bundles
exist in `/Applications`.

## Shell Layout

The tracked zsh files are thin entrypoints:

- `home/.zshenv`
- `home/.zprofile`
- `home/.zshrc`
- `home/.config/zsh/path.zsh`
- `home/.config/zsh/env.zsh`
- `home/.config/zsh/profile.zsh`
- `home/.config/zsh/interactive.zsh`
- `home/.config/zsh/aliases.zsh`
- `home/.config/zsh/functions.zsh`
- `home/.config/zsh/check-updates.zsh`

Machine-local secrets and exports belong in ignored files under:

```text
~/.config/local/*.zsh
```

Use environment variables for secrets and the zsh `path` array for committable
PATH setup.

When a clean shell does not have `mise` shims on `PATH`, prefer:

```bash
mise exec -- <command>
```

## Mackup and Raycast

Mackup uses iCloud storage and an explicit app allowlist:

```bash
./bin/mackup-backup
./bin/mackup-restore
```

The allowlist currently includes Cursor, Cyberduck, Rectangle, Spotify, VS Code,
GitHub CLI, Lazygit, and Stats.

Use the helper scripts instead of raw Mackup link mode. This repo treats Mackup
as an explicit copy-based backup/restore tool so tracked files under `home/`
remain the source of truth.

Raycast is separate:

```bash
./bin/raycast-backup
./bin/raycast-restore
```

Keep `.rayconfig` exports and passphrases outside git.

## Neovim

`nvim/` is a git submodule with separate history. `bin/link-dotfiles` links it
to:

```text
~/.config/nvim
```

Do not edit the submodule from this repo unless the task is explicitly about
the Neovim config repo.

## Updating an Existing Mac

Pull repo updates and reapply bootstrap-managed changes:

```bash
dotfiles-update
```

That command runs `git pull --ff-only` and then `bin/bootstrap` with macOS
defaults skipped for the update run.

For targeted reruns:

```bash
./bin/preflight
./bin/bootstrap
./bin/install-apps
./bin/link-dotfiles
./bin/setup-tmux
./bin/app-state-doctor
```

## Validation

After meaningful changes, run the smallest relevant checks:

```bash
bash -n bin/bootstrap
bash -n bin/link-dotfiles
bash -n macos/defaults.sh
git diff --check
```

For setup or inventory changes, also run:

```bash
./bin/preflight
./bin/install-apps --dry-run
./bin/setup --dry-run
```

Keep `README.md`, `QUICKSTART.md`, scripts, and tracked config aligned. If the
implementation changes, update the docs in the same patch.
