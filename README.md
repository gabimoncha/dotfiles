# dotfiles

Bootstrap a new Mac from the current machine state without tracking shell secrets.

## What This Repo Owns

- Homebrew packages through `Brewfile`
- Global `mise` tool versions
- Git, tmux, Karabiner, Zed, and selected helper scripts
- VS Code and Cursor user settings/keymaps
- macOS defaults that are safe to automate
- Neovim as a separate git repo wired in here as a submodule

## What This Repo Does Not Own Yet

- `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.p10k.zsh`
- Token-bearing app configs like Raycast auth
- Cache-like config files and workspace/session state

## Bootstrap

```bash
git clone <dotfiles-remote> ~/dotfiles
cd ~/dotfiles
./bin/bootstrap
```

The bootstrap script:

1. Installs Homebrew if needed.
2. Initializes git submodules.
3. Installs all packages from `Brewfile`.
4. Symlinks managed files from `home/` into `$HOME`.
5. Installs global `mise` tools.
6. Applies tracked macOS defaults.

## Neovim Submodule

`nvim/` is wired as a git submodule and currently points at `../nvim`.

That means the current layout expects:

- `dotfiles` and `nvim` to live as sibling repos
- or the submodule URL to be replaced with a real remote once you publish the Neovim repo

Until the Neovim repo has a remote, `./bin/bootstrap` will warn if it cannot initialize that submodule.

## Managed Files

- `home/.gitconfig`
- `home/.tmux.conf`
- `home/.config/mise/config.toml`
- `home/.config/karabiner/karabiner.json`
- `home/.config/zed/settings.json`
- `home/.config/zed/keymap.json`
- `home/Library/Application Support/Code/User/settings.json`
- `home/Library/Application Support/Code/User/keybindings.json`
- `home/Library/Application Support/Cursor/User/settings.json`
- `home/Library/Application Support/Cursor/User/keybindings.json`
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
