# Repository rules

This repository owns setup, tool inventories, and selected app settings for
the owner's Macs and for Linux hosts: Docker containers and VMs. Read
[README.md](README.md) for the workflow and [DECISIONS.md](DECISIONS.md)
before changing ownership, bootstrap boundaries, or other design decisions.
For mise behavior, the source of truth is the mise documentation at
<https://mise.jdx.dev>, for the mise version that this repository pins.

## Where things live

| To change                                          | Edit                                                                                                                               |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| An app's settings file                             | `configs/<app>/`                                                                                                                   |
| Where a file goes in HOME                          | the `[dotfiles]` entry in a root mise file                                                                                         |
| Entries for every host                             | `mise.toml`                                                                                                                        |
| Entries for one platform                           | `mise.macos.toml` or `mise.linux.toml`                                                                                             |
| Entries for one machine                            | the profile file: `mise.macowl.toml`, `mise.air.toml`, `mise.container.toml`, or `mise.vm.toml`                                    |
| Agent and T3 settings that sync between machines   | the merge sources in `configs/claude/`, `configs/codex/`, and `configs/t3/`; save them with `./bin/save-settings`                  |
| Which agent settings sync                          | `configs/<app>/sync-keys`: one `public` rule per setting, including each key of the merge source, and `private` rules for sections |
| Agent rules for every host                         | `configs/agents/instructions.md`                                                                                                   |
| Agent rules for one host                           | `configs/agents/<profile>.md`                                                                                                      |
| Runtime tools and mise tasks                       | `configs/mise/config/config.toml`                                                                                                  |
| Runtime tools for one profile                      | `configs/mise/config/config.<profile>.toml`                                                                                        |
| Homebrew formulae, casks, and App Store apps       | `Brewfile`                                                                                                                         |
| Apt packages                                       | `mise.linux.toml` or the profile file                                                                                              |
| macOS preferences                                  | `[bootstrap.macos]` in `mise.macos.toml`, and `macos/defaults.sh`                                                                  |
| Agent CLIs, mise, and other vendor-installed tools | `apps/standalone.tsv`                                                                                                              |
| Setup steps                                        | `bin/`                                                                                                                             |

Apply file changes with `./bin/link-dotfiles`. Preview them first with
`./bin/link-dotfiles --dry-run`. Apply them only from the main checkout,
after the change merges. Run other mise commands for this repository
through `./bin/repo-mise`, which loads the selected profile and the pinned mise.

## Add a config file

1. Put the file in `configs/<app>/`. Use the app's short name for the folder.
2. Add a `[dotfiles]` entry to the root mise file for the hosts that need it.
   Use `mode = "symlink"` when the app only reads the file. Use `merge = true`
   when the app also writes the file, and add a `sync-keys` list next to the
   source. Agent settings are merges, because the agents write private paths
   into them. `./bin/save-settings` copies only the public keys back.
3. Run `./bin/link-dotfiles --dry-run`. Run `./bin/link-dotfiles` from the
   main checkout after the change merges.
4. Run `./bin/preflight`. It fails when a file in `configs/` has no entry.

## Platforms

Every shared file runs on macOS and on Linux (Debian and Ubuntu). Shared files
include app sources that both systems use, the `bin/` scripts that both setups
run, and the mise tool list. A change that works only on the Mac breaks Linux.

- Write shell scripts for Bash 3.2 (macOS `/bin/bash`) and for both BSD and
  GNU tools. Where the tools differ (`sed -i`, `stat`, `date`, `shasum` and
  `sha256sum`), branch on `uname -s`, as `standalone_sha256` in
  `bin/lib/standalone.sh` does. Setup's Ruby helpers run on `/usr/bin/ruby`:
  2.6 on macOS, 3.1 on Debian 12, and 3.3 on Debian 13.
- Gate macOS-only behavior: `$OSTYPE == darwin*` in zsh, `uname -s` in Bash,
  `os = "macos"` on a mise tool, and `mise.macos.toml` for file entries.
- Linux hosts have no Homebrew, GUI apps, launchd, or Keychain. A container
  can also lack systemd and the agent sandboxes.

## Editing

- Edit tracked sources here, not live files under HOME.
- Edit only in a worktree or on a branch, never on `main`.
- Keep setup rerunnable. Preserve link backups and existing user state.
- `bin/setup` lists the setup steps in order: two phases on macOS, one on
  Linux. The step functions are in `bin/lib/setup-steps.sh`. Mark a step
  `--optional` when the later steps can run without it.
- Add GUI apps through mas when available, then use mise for supported tools,
  then Homebrew. Coding agent CLIs, mise, and the Linux T3 server are
  standalone exceptions, listed in `apps/standalone.tsv`.
  The T3 nightly desktop app stays in Homebrew.
- Steam uses `bin/install-steam` for Valve's verified ARM64 bootstrapper.
  Preserve its update channel and quarantine. Keep Rosetta installation manual.
- Keep Brewfile entries alphabetized within sections unless deliberately grouped.
- mise installs `npm:` tools with Bun, and Bun applies its own release delay.
  When you add or remove an `npm:<package>` entry in `minimum_release_age_excludes`
  in `configs/mise/config/config.toml`, make the same change for `<package>` in
  `minimumReleaseAgeExcludes` in `configs/bun/bunfig.toml`. If `mise up` then
  fails with `<name>@<version> failed to resolve`, add that dependency to the
  Bun list too. When the tool ships its binary in platform packages, such as
  `@tsrs/darwin-arm64`, add the macos-arm64 and linux-x64 packages too. Bun
  skips a blocked platform package with no error, and the tool fails to start.
- Set a tool on `minimum_release_age_excludes` to `latest`. Don't pin its
  version; `mise.lock` records it. `github:flowcopilot/aether` stays pinned,
  because mise finds no releases for it.
- Keep local companions under ignored `local/`; only examples belong in Git.
- Keep the profile checks in `bin/lib/dotfiles-profile.sh` before setup writes.
  The Air and VM profiles stay deferred.
- Never commit credentials, private identities, backup payloads, or machine-local
  state. See [SECURITY.md](SECURITY.md).
- Keep test fixtures and diagnostic scratch files in system temporary directories.
  Setup logs use ignored `.local/setup-runs/` with automatic retention.
- `nvim/` is a separate repository. Do not edit it unless explicitly requested.
- Keep macOS changes conservative and reversible. Correct documentation drift
  when found; distinguish current behavior from proposed fixes.
- Write every PR body from `.github/pull_request_template.md`. Delete the
  sections that do not apply. `gh pr create --body` skips the template.

## Backup and sync

Sync and back up before a setup test, a restore, or a new Mac. Then the
repository and the backups hold this machine's current state. Each step is a
mise task in `configs/mise/config/config.toml`; `mise tasks` lists them.

1. Sync the repository. `mise run dot:save` copies the public agent and T3
   settings into `configs/`. `mise run dot:drift` reports the installed apps
   and tools that differ from `Brewfile`, `apps/mobile.Brewfile`, and the mise lists. The user's
   commits are pushed.
2. Back up portable state with `mise run backup`: Mackup app settings, an
   encrypted Codex archive, and a Raycast export. The user types the
   passwords and completes the Raycast export in its window.
3. The backup is done when the new files are in the Synology or iCloud
   folders of [MACKUP.md](MACKUP.md). A zero exit status does not prove it.

`mise run restore` restores this state. `./bin/file-restore --debug` shows the
storage folders.

When you add, rename, or remove a backup or sync script, update its mise task
and this section in the same change.

## Setup repairs

When a `./bin/setup` step fails, is blocked, or is deferred, or the user asks
you to repair setup, follow [SETUP-AGENT.md](SETUP-AGENT.md). Put each
repeatable setup step in a `bin/` script. The guide covers failures and
judgment only.

## Apple releases

Use only public macOS, Xcode, iOS and simulator releases. Setup must stop when
macOS updates are available, update status is unknown, or macOS/Xcode appears
to be a prerelease. Do not install OS updates or change beta enrollment.
Pass `--allow-macos-beta` only when the user asks for it.
Direct the user to System Settings, restart if needed, and rerun setup.

## Validation

The repo has no test suite. Run `bash -n` or `zsh -n` on changed shell files,
`./bin/preflight`, and `git diff --check`. For setup or app-install changes,
also run the matching `--dry-run` path. Do not validate with live installs,
account changes, personal restores, or macOS defaults. For a change to a shared
file, run the same checks on a Linux host when you can reach one. Report what
remains unchecked on a real Mac and on Linux.
