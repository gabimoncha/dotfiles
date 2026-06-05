# Agent Workspace

This repo is the source of truth for new-Mac setup. Work in tracked source files, not live files in `$HOME`.

## Priorities

- Preserve bootstrap idempotency.
- Keep Homebrew and mise ownership separate.
- Keep secrets and machine-local state out of git.
- Prefer small validation commands after focused changes.

## Common Checks

```bash
bash -n bin/bootstrap
bash -n bin/setup
bash -n bin/link-dotfiles
bash -n bin/install-apps
bash -n macos/defaults.sh
git diff --check
./bin/install-apps --dry-run
./bin/setup --dry-run
```

## Ownership

- `Brewfile`: Homebrew taps, formulae, casks, and VS Code extensions.
- `home/.config/mise/config.toml`: runtimes and mise-supported CLIs.
- `apps/manifest.tsv`: typed setup ledger for cask/formula/mise/mas/manual app status.
- `home/`: symlink source of truth for tracked home files.
- `nvim/`: separate submodule; do not edit from this repo unless the task is explicitly about the Neovim config.
