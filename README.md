# dotfiles

Bootstrap a new Mac from the current machine state without tracking shell secrets.

## What This Repo Owns

- Homebrew packages, App Store apps, and editor extensions through `Brewfile`
- Global `mise` tool versions
- Git, zsh, tmux, Karabiner, Zed, AeroSpace, Ghostty, superwhisper preferences, Mackup, and selected helper scripts
- VS Code and Cursor user settings/keymaps through Mackup
- macOS defaults that are safe to automate
- Neovim as a separate git repo wired in here as a submodule

## What This Repo Does Not Own

- Shell secrets and machine-local exports under `~/.config/local/*.zsh`
- Token-bearing app configs, Raycast export passphrases, and app auth/permission state
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
3. Installs `mise` if needed.
4. Initializes git submodules.
5. Symlinks managed files from `home/` into `$HOME` so the global mise config and shims are available.
6. Installs global `mise` tools in the background while Homebrew continues.
7. Installs packages, App Store apps, and editor extensions from a filtered `Brewfile` so existing apps in `/Applications` or unsigned App Store state do not break the run.
8. Verifies configured mise tools with `bin/check-mise-tools`, then installs any Xcode-dependent formulae once Xcode is ready.
9. Installs missing tmux plugins through TPM.
10. Installs Oh My Zsh and Powerlevel10k if missing.
11. Applies tracked macOS defaults once, unless `DOTFILES_SKIP_MACOS_DEFAULTS=1` is set.

## Neovim Submodule

`nvim/` is wired as a git submodule using the public-friendly relative URL `../nvim`. HTTPS clones of this repo resolve it to the public `gabimoncha/nvim` repo without requiring GitHub SSH first.

`bin/link-dotfiles` links that submodule to `~/.config/nvim`, so the setup is both:

- submodule for separate Neovim repo history
- symlink for the path Neovim expects on macOS

Run `./bin/auth-setup` after bootstrap to configure GitHub SSH for day-to-day development.

## Extra Apps

`Brewfile` owns normal Homebrew formulae, casks, VS Code extensions, and App Store apps via `mas`. App Store installs require an Apple ID signed in to the App Store; if setup skips them, sign in and rerun `./bin/setup`.

Full Xcode is installed through the `xcodes` CLI managed by `mise`, then selected with `xcode-select` and license-accepted if needed. Xcode-dependent formulae such as `idb-companion` and `sourcekitten` are deferred until after the mise tool install completes so setup does not run competing `mise install` jobs.

`apps/manifest.tsv` is the typed setup ledger for extra tools and apps that need explicit handling outside the main `Brewfile` pass.

Manifest types:

- `cask`: Supplemental Homebrew GUI apps.
- `formula`: Supplemental Homebrew CLIs that `mise ls-remote <tool>` does not support.
- `mise`: CLIs that are owned by `home/.config/mise/config.toml`.
- `manual`: vendor/account flows such as DaVinci Resolve and Pinokio.

NearDrop is installed from the `grishka/grishka` Homebrew tap. Bootstrap and `install-apps` both remove the app quarantine attribute after install so the app can launch cleanly.

superwhisper is installed as a Homebrew cask, and `bin/link-dotfiles` symlinks the tracked settings file to `~/Documents/superwhisper/settings/settings.json`. App auth and macOS permissions still need to be granted outside git.

AeroSpace and Ghostty are installed as Homebrew casks, but their configs are tracked directly in this repo. `bin/link-dotfiles` only links `~/.aerospace.toml` and `~/Library/Application Support/com.mitchellh.ghostty/config` after the matching app bundle exists in `/Applications`; setup reruns the link step after app installation so fresh machines get these links at the right time.

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

- `home/.zshenv`, `home/.zprofile`, and `home/.zshrc` as thin zsh entrypoints
- `home/.p10k.zsh`
- `home/.config/zsh/*.zsh` for the actual shared zsh configuration

Machine-local secrets and exports belong in `~/.config/local/*.zsh`, which is ignored by this repo and sourced by `.zshrc`.

Mise-owned command shims live at `~/.local/share/mise/shims` and are placed on `PATH` by `home/.config/zsh/path.zsh`. After bootstrap, `./bin/check-mise-tools` verifies that every configured mise tool is installed and that critical commands such as `tmux`, `gh`, `bun`, and `vercel` resolve through the shell.

tmux plugins are installed by `./bin/setup-tmux`, which bootstrap runs after `mise install`. Rerun it directly if tmux starts with keybindings but without the theme/status/plugins.

## Mackup and Raycast

Mackup is configured in copy mode with iCloud storage:

```bash
./bin/mackup-backup
./bin/mackup-restore
```

Both helpers read the tracked `home/.mackup.cfg` and defer cleanly if iCloud Drive is not signed in yet. Mackup does not restore Raycast in this repo.

Raycast is restored through an encrypted `.rayconfig` export saved outside git under `iCloud Drive/Raycast`:

```bash
# old Mac: create the export
./bin/raycast-backup

# new Mac: open the export after iCloud syncs it
./bin/raycast-restore
```

You can still pass an explicit export path to `./bin/raycast-restore /path/to/export.rayconfig`.

Do not commit `.rayconfig` files or export passphrases. Raycast encrypts exports, but they still contain app settings and extension state; keep the passphrase in Keychain or another private store.

macOS defaults disable Spotlight's Command-Space hotkeys. Raycast owning Command-Space comes from the restored Raycast export or from setting the hotkey manually in Raycast preferences. The defaults script also hides the Dock automatically, enables the Romanian keyboard input source alongside the existing input sources, and configures Dictation for Romanian and English. Romanian input source setup uses Apple's Text Input Source API through `macos/ensure-input-sources.swift` because writing `com.apple.HIToolbox` alone does not reliably update System Settings on current macOS.

Battery Charge Limit is a native macOS Tahoe 26.4+ setting on Apple silicon Macs, but this repo does not currently script it because Apple documents the System Settings and Shortcuts flows, not a stable `defaults` or `pmset` setter. On a fresh Mac, set it from System Settings > Battery > Charging > Charge Limit > 80%.

Run `./bin/app-state-doctor` when AeroSpace, Ghostty, tmux plugins, or Raycast hotkeys look incomplete after a fresh-machine setup. It checks for the tracked app config links, missing tmux plugins, Raycast exports, and whether Spotlight is still holding Command-Space.

## Managed Files

- `home/.gitconfig`
- `home/.aerospace.toml`
- `home/.zshenv`, `home/.zprofile`, and `home/.zshrc`
- `home/.p10k.zsh`
- `home/.mackup.cfg`
- `home/.rgrc`
- `home/.tmux.conf`
- `home/.config/mise/config.toml`
- `home/.config/zsh/*.zsh`
- `home/.config/karabiner/karabiner.json`
- `home/.config/zed/settings.json`
- `home/.config/zed/keymap.json`
- `home/Library/Application Support/com.mitchellh.ghostty/config`
- `home/Documents/superwhisper/settings/settings.json`
- `home/scripts/toggle_function_keys.sh`
- `nvim/` as `~/.config/nvim`

## Git Identity

The tracked git config keeps shared defaults and includes `~/.gitconfig.local`.
`./bin/auth-setup` prompts for missing Git identity and writes it to that local-only file.

You can also edit it manually:

```ini
[user]
	name = your-name
	email = your-github-private-email@users.noreply.github.com
```

Do not sync this through Mackup or commit it to the repo; it can contain private account identity.

## Future Shell Cleanup

The intended commit-safe shell layout is:

- tracked: `~/.config/zsh/path.zsh`, aliases, prompt-agnostic shell logic
- ignored: `~/.config/local/env.zsh` for API keys and machine-specific exports

Pattern:

```zsh
[ -f "$HOME/.config/local/env.zsh" ] && source "$HOME/.config/local/env.zsh"
```

Keep API keys in environment variables, not in `PATH`. Use the zsh `path` array for the committable PATH setup.
