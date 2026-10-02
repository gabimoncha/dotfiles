# Repository rules

This repository owns Mac setup, tool inventories, and selected app settings.
Read [README.md](README.md) for the workflow and [DECISIONS.md](DECISIONS.md)
before changing ownership, bootstrap boundaries, or other design decisions.

## Editing

- Edit tracked sources here, not live files under HOME.
- Keep setup rerunnable. Preserve link backups and existing user state.
- `bin/setup` owns the two-phase planner; `bin/bootstrap` delegates to it.
- Add GUI apps through mas when available, then use mise for supported tools,
  then Homebrew. Coding agent CLIs and mise are explicit standalone exceptions.
  Orca and the T3 nightly desktop app stay in Homebrew.
- Keep Brewfile entries alphabetized within sections unless deliberately grouped.
- Put managed files under `home/`, wire them through `bin/link-dotfiles`, and
  update the relevant documentation. Keep local companions under ignored
  `home/.config/local/`; only examples belong in Git.
- Never commit credentials, private identities, backup payloads, or machine-local
  state. See [SECURITY.md](SECURITY.md).
- `nvim/` is a separate repository. Do not edit it unless explicitly requested.
- Keep macOS changes conservative and reversible. Correct documentation drift
  when found; distinguish current behavior from proposed fixes.

## Apple releases

Use only public macOS, Xcode, iOS and simulator releases. Setup must stop when
macOS updates are available, update status is unknown, or macOS/Xcode appears
to be a prerelease. Do not install OS updates or change beta enrollment.
Direct the user to System Settings, restart if needed, and rerun setup.

## Validation

Run syntax checks for changed Bash/zsh files, the relevant `tests/*.sh` suites
with Bash, and `git diff --check`. For setup or app-install changes, also check
the applicable dry-run path. Preserve tests for failures and interrupted runs.

Tests must use isolated state and fake external commands, not live installs,
account changes, personal restores, or macOS defaults. Process cancellation
tests need process inspection. A passing fixture suite does not establish a
successful fresh-Mac setup; report what remains untested.
