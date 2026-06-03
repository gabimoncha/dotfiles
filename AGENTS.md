# Dotfiles Repo Guide

## Purpose

This repo is the source of truth for setting up a new MacBook. It owns machine bootstrap, selected app settings, and a curated set of developer tools without committing secrets or machine-local noise.

## What This Repo Owns

- `Brewfile` for Homebrew formulae, casks, taps, and VS Code extensions
- `home/` for files that will be symlinked into `$HOME`
- `bin/setup` for one-command first-run machine setup
- `bin/bootstrap` for lower-level bootstrap work
- `bin/link-dotfiles` for idempotent linking plus backups of replaced targets
- `macos/defaults.sh` for safe automatable macOS defaults
- `nvim/` as a git submodule, linked to `~/.config/nvim`

## Operating Rules

- Edit the tracked source in this repo, not the live file under `$HOME`.
- Keep package ownership clean:
  - `Brewfile` owns system packages, GUI apps, and CLIs that should come from Homebrew.
  - `home/.config/mise/config.toml` owns language runtimes and globally installed dev tools managed by `mise`.
- Do not add secrets, tokens, private emails, machine-local paths, or auth exports to tracked files.
- Preserve the repo's bootstrap model: clone repo, run `./bin/setup`, and end in a usable state on a fresh Mac.
- Preserve idempotency. Re-running bootstrap or link steps should not corrupt an existing machine.
- If changing `bin/link-dotfiles`, keep its backup behavior intact unless there is a strong reason to change it.
- Treat `nvim/` as its own repo. Do not edit submodule contents from here unless the task is explicitly about the Neovim config repo.

## Repo-Specific Conventions

- Keep `Brewfile` entries alphabetized inside their sections unless there is a deliberate grouping reason.
- Prefer adding new managed dotfiles under `home/` and then wiring them through `bin/link-dotfiles`.
- If a new tracked config needs a local-only companion, keep the tracked piece generic and put local-only data under ignored paths such as `home/.config/local/`.
- macOS automation should stay conservative and reversible. Avoid aggressive `defaults write` changes unless they are clearly safe for a fresh-machine bootstrap.
- If you add a new managed file or workflow, update `README.md` so the bootstrap story stays accurate.

## Validation

After meaningful changes, prefer the smallest relevant checks:

```bash
bash -n bin/bootstrap
bash -n bin/link-dotfiles
bash -n macos/defaults.sh
git diff --check
```

For dependency changes, also sanity-check the ownership split:

- Homebrew packages belong in `Brewfile`
- Runtime/tool versions belong in `home/.config/mise/config.toml`

## Notes For Agents

- Be practical and keep this repo boring. Reliability matters more than cleverness.
- When the user asks to add or update a tool, decide whether it belongs in Homebrew or `mise` instead of blindly following the request.
- If you notice config drift between the README, bootstrap scripts, and managed files, fix it rather than documenting a lie.
