# Decisions

## Neovim Is a Submodule and a Symlink

`nvim` is a separate GitHub repo so it keeps independent history. The dotfiles repo tracks it as a submodule, and `bin/link-dotfiles` symlinks `dotfiles/nvim` to `~/.config/nvim`.

This keeps fresh-machine bootstrap simple while preserving the separate Neovim repo.

## Homebrew vs mise vs Vendor Apps

- `Brewfile` owns Homebrew formulae, casks, taps, and VS Code extensions.
- `home/.config/mise/config.toml` owns language runtimes and global dev tools managed by mise.
- `apps/manifest.tsv` tracks cask, formula, and manual/vendor installs that deserve explicit setup status.

Prefer Homebrew casks first. Use vendor/manual fallback only when there is no stable cask or App Store route.

Default setup includes the full mobile development stack because Xcode and iOS platform support dominate fresh-machine time and are safest when started early. Setup prepares `xcodes` and `aria2`, starts the Xcode install while Homebrew and `mise` work continue, then finishes iOS platform support and Xcode-dependent formulae after Xcode is selected. `DOTFILES_SKIP_MOBILE_DEV=1` or `./bin/setup --skip-mobile-dev` keeps a lightweight run available.

Xcode installs default to the latest release channel; `DOTFILES_XCODE_CHANNEL=prerelease` opts into prereleases. Xcode installs use `xcodes --experimental-unxip` by default because Xcode archives dominate setup time; `DOTFILES_XCODE_EXPERIMENTAL_UNXIP=0` keeps the regular unxip path available. Xcode-sensitive Homebrew formulae stay in `Brewfile` as the source of truth and are deferred until full Xcode is selected.

Setup parallelism is on by default, but only across independent work. Homebrew writers and `mise install` writers stay serialized; recoverable failures are recorded, independent work continues, and the final summary exits nonzero when repair is needed.

## Mackup Is Copy-Mode and Allowlisted

Mackup is part of the new-Mac workflow, but only through explicit copy-mode
backup/restore helpers under `bin/file-backup` and `bin/file-restore`. The
tracked `home/.mackup.cfg` uses Synology Drive file-system storage and a small
allowlist so Mackup does not try to own files this repo already symlinks. The
backup helper mirrors successful Synology backups to iCloud as a best-effort
secondary copy, and restore falls back to iCloud when the Synology backup is not
available yet.

Raycast stays out of the Mackup allowlist unless Mackup provides a narrow supported profile. The primary Raycast source of truth is the encrypted `.rayconfig` export/import flow, saved under Synology Drive and mirrored to iCloud, which avoids syncing the full app support directory.

## Codex State Uses Encrypted Archives

Durable, safe AI tooling assets can live in this repo and be linked through
`bin/link-dotfiles`. User-authored global Codex skills live under
`home/.agents/skills`, linked to `~/.agents/skills`.

Codex memories and selected user config stay out of git and Mackup. `~/.codex`
contains auth, histories, databases, caches, worktrees, plugin assets, generated
memories, project/workspace state, and connection state in one tree, so the repo
backs up only a curated allowlist through `bin/file-backup codex` as an `age`
passphrase-encrypted archive. Scheduled task definitions are included because
they are useful portable automation intent; raw Codex global app state is not
included because it carries machine/project state that should be fresh per Mac.
Synology Drive is the primary target and iCloud is the secondary copy. Restore
is explicit or prompted during the interactive setup follow-up.

## Explicit Updates With a Daily Notifier

There is no automatic Homebrew upgrade LaunchAgent. The shell runs a non-blocking daily update check and reports when `origin/main` has new commits. Applying updates remains explicit through `dotfiles-update`.
