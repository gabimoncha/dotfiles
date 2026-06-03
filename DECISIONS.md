# Decisions

## Neovim Is a Submodule and a Symlink

`nvim` is a separate GitHub repo so it keeps independent history. The dotfiles repo tracks it as a submodule, and `bin/link-dotfiles` symlinks `dotfiles/nvim` to `~/.config/nvim`.

This keeps fresh-machine bootstrap simple while preserving the separate Neovim repo.

## Homebrew vs mise vs Vendor Apps

- `Brewfile` owns Homebrew formulae, casks, taps, and VS Code extensions.
- `home/.config/mise/config.toml` owns language runtimes and global dev tools managed by mise.
- `apps/manifest.tsv` tracks apps that deserve explicit setup status, especially apps that are not cleanly scriptable.

Prefer Homebrew casks first. Use vendor/manual fallback only when there is no stable cask or App Store route.

## Mackup Is Copy-Mode and Allowlisted

Mackup is part of the new-Mac workflow, but only through explicit copy-mode backup/restore helpers. The tracked `home/.mackup.cfg` uses iCloud and a small allowlist so Mackup does not try to own files this repo already symlinks.

Raycast stays out of the Mackup allowlist unless Mackup provides a narrow supported profile. The primary Raycast source of truth is the encrypted `.rayconfig` export/import flow, which avoids syncing the full app support directory.

## Explicit Updates With a Daily Notifier

There is no automatic Homebrew upgrade LaunchAgent. The shell runs a non-blocking daily update check and reports when `origin/main` has new commits. Applying updates remains explicit through `dotfiles-update`.
