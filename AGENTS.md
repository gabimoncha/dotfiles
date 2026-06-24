# Dotfiles Repo Guide

## Purpose

This repo is the source of truth for setting up a new MacBook. It owns machine bootstrap, selected app settings, and a curated set of developer tools without committing secrets or machine-local noise.

## What This Repo Owns

- `Brewfile` for Homebrew formulae, casks, taps, and VS Code extensions
- `mise` for runtimes and cli tools
- `home/` for files that will be symlinked into `$HOME`
- `bin/setup` for one-command first-run machine setup
- `bin/bootstrap` for lower-level bootstrap work
- `bin/link-dotfiles` for idempotent linking plus backups of replaced targets
- `macos/defaults.sh` for safe automatable macOS defaults
- `nvim/` as a git submodule, linked to `~/.config/nvim`

## Operating Rules

- Edit the tracked source in this repo, not the live file under `$HOME`.
- Keep package ownership clean:
  - Prefer `mas` for GUI apps that exist in the Mac App Store.
  - Prefer `home/.config/mise/config.toml` for language runtimes and globally installed developer tools when `mise` supports them.
  - Use `Brewfile` for Homebrew formulae, casks, taps, VS Code extensions, and anything that does not belong in `mas` or `mise`.
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
bash -n bin/setup
bash -n bin/link-dotfiles
bash -n bin/install-apps
bash -n macos/defaults.sh
git diff --check
```

For setup or app-install changes, also use the relevant dry-run path such as `./bin/setup --dry-run` or `./bin/install-apps --dry-run`.

For dependency changes, also sanity-check the ownership split:

- Mac App Store apps belong in the `mas` inventory.
- Runtime/tool versions belong in `home/.config/mise/config.toml` when supported by `mise`.
- Homebrew packages belong in `Brewfile` only after `mas` and `mise` have been ruled out.

## Notes For Agents

- Be practical and keep this repo boring. Reliability matters more than cleverness.
- Before changing setup ownership, bootstrap boundaries, app install ownership, or other durable architecture decisions, read `DECISIONS.md` and update it when the rationale changes.
- When the user asks to add or update an app or tool, choose ownership in this order: `mas` for Mac App Store apps, then `mise` for supported runtimes/developer tools, then Homebrew through `Brewfile`.
- If you notice config drift between the README, bootstrap scripts, and managed files, fix it rather than documenting a lie.
