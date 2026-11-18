# Repository rules

This repository owns setup, tool inventories, and selected app settings for
the owner's Macs and for Linux hosts in Docker containers. Read
[README.md](README.md) for the workflow and [DECISIONS.md](DECISIONS.md)
before changing ownership, bootstrap boundaries, or other design decisions.
For mise behavior, the source of truth is the mise documentation at
<https://mise.jdx.dev>, for the mise version that this repository pins.

## Where things live

| To change                                                       | Edit                                                                                                                               |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| An app's settings file                                          | `configs/<app>/`                                                                                                                   |
| Where a file goes in HOME                                       | the `[dotfiles]` entry in a root mise file                                                                                         |
| Entries for every host, the MacBook Air too                     | `mise.toml`                                                                                                                        |
| Entries for the development machines (every profile except air) | `mise.devhost.toml`                                                                                                                |
| Entries for one platform                                        | `mise.macos.toml` or `mise.linux.toml`                                                                                             |
| Entries for one machine                                         | the profile file: `mise.macowl.toml`, `mise.macmini.toml`, `mise.air.toml`, or `mise.container.toml`                               |
| Agent and T3 settings that sync between machines                | the merge sources in `configs/claude/`, `configs/codex/`, and `configs/t3/`; save them with `./bin/save-settings`                  |
| Which agent settings sync                                       | `configs/<app>/sync-keys`: one `public` rule per setting, including each key of the merge source, and `private` rules for sections |
| Agent rules for every development host                          | `configs/agents/instructions.md`                                                                                                   |
| Agent rules for one host                                        | `configs/agents/<profile>.md`                                                                                                      |
| Installed agent skills                                          | `configs/agents/skills/` and `configs/agents/skill-lock.json`, through the `skills` CLI                                            |
| Runtime tools and mise tasks                                    | `configs/mise/config/config.toml` for every host; `config.devhost.toml` for the development machines                               |
| Runtime tools for one profile                                   | `configs/mise/config/config.<profile>.toml`                                                                                        |
| Homebrew formulae, casks, and App Store apps                    | `Brewfile` for every Mac; `apps/devhost.Brewfile` for macowl and macmini; `apps/<profile>.Brewfile` for one Mac                    |
| Manifest apps                                                   | `apps/manifest.tsv` for every Mac; `apps/manifest.devhost.tsv` and `apps/manifest.<profile>.tsv` as for the Brewfiles              |
| Apt packages                                                    | `mise.linux.toml` or the profile file                                                                                              |
| macOS preferences, Dock apps, and login items                   | `[bootstrap.settings.macos]` in `mise.macos.toml`, `mise.devhost.toml`, or the profile file, and `macos/defaults.sh`               |
| Agent CLIs, mise, and other vendor-installed tools              | `apps/standalone.tsv`                                                                                                              |
| Setup steps                                                     | `bin/`                                                                                                                             |

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

## mise first

Before you propose or write a `bin/` script, a shell function, a Homebrew
entry, or a manual step, find the mise feature for the need, and read its page
at the pinned tag. Put the result in your recommendation: the mise feature
that fits, or the gap and the documentation section that shows it. Write a
script only for a gap that mise cannot fill, and record the gap and its
documentation section in a comment or in DECISIONS.md.

| Need                                           | mise feature                                                     |
| ---------------------------------------------- | ---------------------------------------------------------------- |
| A file or link in HOME, and its mode           | `[dotfiles]`: `mode`, `merge`, `permissions`, `symlink-each`     |
| Local history of a file that an app rewrites   | `[dotfiles]` with `mode = "track-local"`                         |
| A file or a block of lines outside HOME        | `[bootstrap.files]`, with `block` for a file that macOS owns     |
| A Git checkout, such as a shell plugin         | `[bootstrap.repos]`; update with `bootstrap repos update`        |
| A system package and its upgrade               | `[bootstrap.packages]`; `bootstrap packages upgrade`             |
| A macOS preference, login item, or Dock app    | `[bootstrap.settings.macos]`: `defaults`, `login_items`, `dock`  |
| A login job                                    | `[bootstrap.macos.launchd.agents]`; mise expands `~/`            |
| A CLI tool, runtime, or JDK                    | `[tools]`; check `mise registry <name>` first                    |
| Shims, pruning, release age, retries, or trust | `[settings]`; read `settings.toml` at the pinned tag             |
| A readiness or drift check                     | `[doctor.checks]`, `bootstrap status --missing`, `ls --missing`  |
| A command for people or agents                 | a task: `dot:<name>` in the global config, or one in `mise.toml` |
| A reminder after a file in this repo changes   | `[[watch_files]]`                                                |

Read mise state with `--json`, for example `ls --json` or
`lock --sidecars --json`, not by parsing table output.

## Editing

- Edit tracked sources here, not live files under HOME.
- Edit only in a worktree or on a branch, never on `main`.
- `~/.config/mise` links to `configs/mise/config/` in the main checkout. A
  command that writes global config, such as `mise use -g`,
  `mise settings set`, or `mise lock --global`, changes `main`. Edit the files
  in a worktree, or use `./bin/repo-mise --global`, which uses the worktree's
  copy.
- Keep setup rerunnable. Preserve link backups and existing user state.
- `bin/setup` lists the setup steps in order: two phases on macOS, one on
  Linux. The step functions are in `bin/lib/setup-steps.sh`. Mark a step
  `--optional` when the later steps can run without it.
- To raise the mise pin, change `bin/lib/mise-pin.sh` (the version and the
  installer SHA-256) and both `min_version` values in one change. Then read
  the mise changelog since the old pin, and recheck each workaround that names
  a mise limit: the Homebrew notes in `apps/manifest*.tsv`, the reasons in
  DECISIONS.md for a script or a Homebrew entry, and the pinned tool versions.
- Add GUI apps through mas when available, then use mise for supported tools,
  then Homebrew. Coding agent CLIs, mise, and the T3 server on Linux and on
  the Mac mini are standalone exceptions, listed in `apps/standalone.tsv`.
  The T3 nightly desktop app stays in Homebrew, for macowl only.
- The Mac mini gets only the shared Mac lists. Put an app, tool, or setting
  that only macowl needs in the macowl files, not in a shared list.
- Steam uses `bin/install-steam` for Valve's verified ARM64 bootstrapper.
  Preserve its update channel and quarantine. Keep Rosetta installation manual.
- Keep Brewfile entries alphabetized within sections unless deliberately grouped.
- mise installs `npm:` tools with Bun, and Bun applies its own release delay.
  When you add or remove an `npm:<package>` entry in `minimum_release_age_excludes`
  in `configs/mise/config/config.toml`, make the same change for `<package>` in
  `minimumReleaseAgeExcludes` in `configs/bun/bunfig.toml`. If `mise up` then
  fails with `<name>@<version> failed to resolve`, add that dependency to the
  Bun list too. When the tool ships its binary in platform packages, such as
  `@tsrs/darwin-arm64`, add the macos-arm64 and linux-x64 packages to the Bun
  list by name; Bun has no wildcards. Bun skips a blocked platform package with
  no error, and the tool fails to start. In `configs/pnpm/config.yaml`, add a
  pattern such as `@tsrs/*`, because pnpm checks the packages of every
  platform and stops on a blocked one.
- Set a tool on `minimum_release_age_excludes` to `latest`. Don't pin its
  version; `mise.lock` records it.
- Change the installed skills with the `skills` CLI, not by hand: `skills add
  <source> -g -a claude-code codex -y -s <skill>`, `skills update -g`, or
  `skills remove -g <skill>`. The CLI writes through `~/.agents/skills` into
  `configs/agents/skills/`. Then commit the changes in `configs/agents/`. Do not
  edit or reformat the files of a third-party skill. Before you add a skill
  from a new source, check that its license allows redistribution and add it to
  `licenses/skills/`.
- Keep local companions under ignored `local/`; only examples belong in Git.
- Keep the profile checks in `bin/lib/dotfiles-profile.sh` before setup writes.
- The MacBook Air is not a development machine. Put a development tool, link,
  or app in the devhost layer (`mise.devhost.toml`, `config.devhost.toml`,
  `apps/devhost.Brewfile`), not in a file for every host.
- Never commit credentials, private identities, backup payloads, or machine-local
  state. See [SECURITY.md](SECURITY.md).
- Keep test fixtures and diagnostic scratch files in system temporary directories.
  Setup logs use ignored `.local/setup-runs/` with automatic retention.
- In a test with a temporary `HOME`, do not link the real `~/.local` or mise
  folders into it. mise then installs into the real folder but records paths
  through the temporary one. When the temporary folder is deleted, those
  installs break and `mise prune` stops. For the real tools, set
  `MISE_DATA_DIR` to the real folder path, not to a path through a link.
- In a test, do not set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, or
  `XDG_STATE_HOME` to a temporary folder. Every program in the command reads
  them, not only the one under test. A self-updater, such as the one of Claude
  Code, can then write its files into the temporary folder and move a real
  link, such as `~/.local/bin/claude`, into it. Use the program's own variable,
  such as `GH_CONFIG_DIR` or `MISE_DATA_DIR`.
- Before you delete a temporary folder, find the real paths that point into
  it: `find ~/.local/bin ~/bin -type l -lname '<folder>*'`. Point each one
  back to its target from before the test, and then run the program to check
  it. Then delete the folder. If you cannot restore a link, keep the folder and
  tell the user.
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
   and tools that differ from the Brewfiles and the mise lists. The user's
   commits are pushed.
2. Back up portable state with `mise run dot:backup`: Mackup app settings, an
   encrypted Codex archive, and a Raycast export. On the Mac mini, run only
   `./bin/file-backup raycast`; it has no Mackup and no Synology Drive. The user types the
   passwords and completes the Raycast export in its window.
3. The backup is done when the new files are in the Synology or iCloud
   folders of [MACKUP.md](MACKUP.md). A zero exit status does not prove it.

`mise run dot:restore` restores this state. `./bin/file-restore --debug` shows the
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

The repo has no test suite. Run `./bin/repo-mise run --output summary check`.
It runs `git diff --check`, the mise task checks, and `./bin/preflight`, which
checks the shell syntax, the mise keys, and the lock sidecars. It prints one
line when the checks pass, and the full output when they fail.
`./bin/repo-mise tasks log check` prints the output of the last run. CI runs
the same task on Linux for each pull request. For a tool or lock
change, also run `./bin/repo-mise --global install --locked --dry-run`. For
a `[bootstrap]` or `[dotfiles]` change, also run
`./bin/repo-mise bootstrap status` and read the rows that you changed. For
setup or app-install changes, also run the matching `--dry-run` path.
`./bin/repo-mise doctor project` checks this machine's readiness. Do not
validate with live installs, account changes, personal restores, or macOS
defaults. For a change to a shared
file, run the same checks on a Linux host when you can reach one. Report what
remains unchecked on a real Mac and on Linux.
