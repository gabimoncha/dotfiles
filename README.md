# dotfiles

Bootstrap a new Mac from the current machine state without tracking shell secrets.

## What This Repo Owns

- Homebrew packages, App Store apps, and editor extensions through `Brewfile`
- Global `mise` tool versions
- Git, zsh, tmux, Karabiner, Zed, Mackup, and selected helper scripts
- VS Code and Cursor user settings/keymaps through Mackup
- macOS defaults that are safe to automate
- Neovim as a separate git repo wired in here as a submodule

## What This Repo Does Not Own

- Shell secrets and machine-local exports under `~/.config/local/*.zsh`
- Token-bearing app configs, Raycast export passphrases, and app auth state
- Cache-like config files, histories, databases, and workspace/session state

## Bootstrap

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

`bin/setup` is the fresh-machine entrypoint. It runs preflight, bootstrap, and app installation first, then offers to continue into interactive auth and restore steps. It is safe to rerun as iCloud, App Store, Mackup, and Raycast prerequisites become ready.

If Xcode Command Line Tools are missing, setup launches the Apple installer popup and exits. Finish that installer, then rerun:

```bash
./bin/setup
```

Dry-run the install pass without changing the machine:

```bash
./bin/setup --dry-run
```

The lower-level `bin/bootstrap` script:

1. Launches the Xcode Command Line Tools installer if needed, then exits for a rerun.
2. Installs Homebrew if needed.
3. Initializes git submodules.
4. Installs packages, App Store apps, and editor extensions from a filtered `Brewfile` so existing apps in `/Applications` or unsigned App Store state do not break the run.
5. Installs Oh My Zsh and Powerlevel10k if missing.
6. Symlinks managed files from `home/` into `$HOME`.
7. Installs global `mise` tools.
8. Applies tracked macOS defaults once, unless `DOTFILES_SKIP_MACOS_DEFAULTS=1` is set.

## Neovim Submodule

`nvim/` is wired as a git submodule using the public-friendly relative URL `../nvim`. HTTPS clones of this repo resolve it to the public `gabimoncha/nvim` repo without requiring GitHub SSH first.

`bin/link-dotfiles` links that submodule to `~/.config/nvim`, so the setup is both:

- submodule for separate Neovim repo history
- symlink for the path Neovim expects on macOS

Run `./bin/auth-setup` after bootstrap to configure GitHub SSH for day-to-day development.

## Extra Apps

`Brewfile` owns normal Homebrew formulae, casks, VS Code extensions, and App Store apps via `mas`. App Store installs require an Apple ID signed in to the App Store; if setup skips them, sign in and rerun `./bin/setup`.

Full Xcode is installed before the main Homebrew bundle through the `xcodes` CLI managed by `mise`, then selected with `xcode-select` and license-accepted if needed. This keeps Xcode-dependent formulae such as `idb-companion` and `sourcekitten` from blocking a fresh setup when Xcode is not ready yet.

`apps/manifest.tsv` is the typed setup ledger for extra tools and apps that need explicit handling outside the main `Brewfile` pass.

Manifest types:

- `cask`: Supplemental Homebrew GUI apps.
- `formula`: Supplemental Homebrew CLIs that `mise ls-remote <tool>` does not support.
- `mise`: CLIs that are owned by `home/.config/mise/config.toml`.
- `manual`: vendor/account flows such as DaVinci Resolve and Pinokio.

NearDrop is installed from the `grishka/grishka` Homebrew tap. Bootstrap and `install-apps` both remove the app quarantine attribute after install so the app can launch cleanly.

Run:

```bash
./bin/install-apps
```

Dry-run without installing:

```bash
./bin/install-apps --dry-run
```

## Shell

The tracked shell layout is:

- `home/.zshrc`
- `home/.zprofile`
- `home/.zshenv`
- `home/.p10k.zsh`
- `home/.config/zsh/path.zsh`
- `home/.config/zsh/aliases.zsh`
- `home/.config/zsh/functions.zsh`
- `home/.config/zsh/check-updates.zsh`

Machine-local secrets and exports belong in `~/.config/local/*.zsh`, which is ignored by this repo and sourced by `.zshrc`.

## Mackup and Raycast

Mackup is configured in copy mode with iCloud storage:

```bash
./bin/mackup-backup
./bin/mackup-restore
```

Both helpers read the tracked `home/.mackup.cfg` and defer cleanly if iCloud Drive is not signed in yet.

Raycast should be restored primarily through an encrypted `.rayconfig` export:

```bash
./bin/raycast-backup
./bin/raycast-restore /path/to/export.rayconfig
```

macOS defaults disable Spotlight hotkeys so Raycast can own Command-Space.

## Managed Files

- `home/.gitconfig`
- `home/.zshenv`
- `home/.zprofile`
- `home/.zshrc`
- `home/.p10k.zsh`
- `home/.mackup.cfg`
- `home/.rgrc`
- `home/.tmux.conf`
- `home/.config/mise/config.toml`
- `home/.config/zsh/path.zsh`
- `home/.config/zsh/aliases.zsh`
- `home/.config/zsh/functions.zsh`
- `home/.config/zsh/check-updates.zsh`
- `home/.config/karabiner/karabiner.json`
- `home/.config/zed/settings.json`
- `home/.config/zed/keymap.json`
- `home/scripts/toggle_function_keys.sh`
- `nvim/` as `~/.config/nvim`

## Git Identity

The tracked git config keeps shared defaults plus `user.name`.

Set your private machine-local email in `~/.gitconfig.local`:

```ini
[user]
	email = your-github-private-email@users.noreply.github.com
```

## Future Shell Cleanup

The intended commit-safe shell layout is:

- tracked: `~/.config/zsh/path.zsh`, aliases, prompt-agnostic shell logic
- ignored: `~/.config/local/env.zsh` for API keys and machine-specific exports

Pattern:

```zsh
[ -f "$HOME/.config/local/env.zsh" ] && source "$HOME/.config/local/env.zsh"
```

Keep API keys in environment variables, not in `PATH`. Use the zsh `path` array for the committable PATH setup.
