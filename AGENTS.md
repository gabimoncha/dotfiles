# Repository rules

This repository owns setup, tool inventories, and selected app settings for
the owner's Mac and for Linux hosts: Docker containers and VMs. Read
[README.md](README.md) for the workflow and [DECISIONS.md](DECISIONS.md)
before changing ownership, bootstrap boundaries, or other design decisions.

## Platforms

Every shared file runs on macOS and on Linux (Debian and Ubuntu). Shared files
include app sources that both systems use, the `bin/` scripts that both setups
run, and the mise tool list. A change that works only on the Mac breaks Linux.

- Write shell scripts for Bash 3.2 (macOS `/bin/bash`) and for both BSD and
  GNU tools. Where the tools differ (`sed -i`, `stat`, `date`, `shasum` and
  `sha256sum`), branch on `uname -s`, as `standalone_sha256` in
  `bin/lib/standalone.sh` does. Setup's Ruby helpers run on `/usr/bin/ruby`:
  2.6 on macOS and 3.1 on Debian 12.
- Gate macOS-only behavior: `$OSTYPE == darwin*` in zsh, `uname -s` in Bash,
  `os = "macos"` on a mise tool, and `mise.macos.toml` for native file entries.
- Linux hosts have no Homebrew, GUI apps, launchd, or Keychain. A container
  can also lack systemd and the agent sandboxes. Linux system packages go in
  `linux/mise.linux.toml`. Host files go in `linux/<profile>/`.

## Editing

- Edit tracked sources here, not live files under HOME.
- Keep setup rerunnable. Preserve link backups and existing user state.
- `bin/setup` owns the two-phase macOS plan and the one-phase Linux plan;
  `bin/bootstrap` delegates to it.
- Add GUI apps through mas when available, then use mise for supported tools,
  then Homebrew. Coding agent CLIs, mise, and the Linux T3 server are
  standalone exceptions, listed in `apps/standalone.tsv`.
  The T3 nightly desktop app stays in Homebrew.
- Steam uses `bin/install-steam` for Valve's verified ARM64 bootstrapper.
  Preserve its update channel and quarantine. Keep Rosetta installation manual.
- Keep Brewfile entries alphabetized within sections unless deliberately grouped.
- Put managed sources in root app folders. Declare their targets once in the
  folder's `mise.toml` or platform environment file. Register modules through
  `mise/setup/conf.d/` and exclude their files from project discovery in
  `.miserc.toml`. Keep local companions under ignored `local/`; only examples
  belong in Git. Use `bin/link-dotfiles` for durable backups and native apply.
- Keep runtime tools in `mise/global.toml` and setup declarations in modules.
  `bin/repo-mise --setup` loads those modules from `/`. Preserve profile checks
  before setup writes. Air and VM profiles remain deferred.
- Never commit credentials, private identities, backup payloads, or machine-local
  state. See [SECURITY.md](SECURITY.md).
- Keep test fixtures and diagnostic scratch files in system temporary directories.
  Setup logs use ignored `.local/setup-runs/` with automatic retention.
- `nvim/` is a separate repository. Do not edit it unless explicitly requested.
- Keep macOS changes conservative and reversible. Correct documentation drift
  when found; distinguish current behavior from proposed fixes.
- Write every PR body from `.github/pull_request_template.md`. Delete the
  sections that do not apply. `gh pr create --body` skips the template.

## Setup repairs

When a `./bin/setup` stage fails, is blocked, or is deferred, or the user asks
you to repair setup, follow [SETUP-AGENT.md](SETUP-AGENT.md). Put each
repeatable setup step in a `bin/` script. The guide covers failures and
judgment only.

## Apple releases

Use only public macOS, Xcode, iOS and simulator releases. Setup must stop when
macOS updates are available, update status is unknown, or macOS/Xcode appears
to be a prerelease. Do not install OS updates or change beta enrollment.
Direct the user to System Settings, restart if needed, and rerun setup.

## Validation

The repo has no test suite. Run `bash -n` or `zsh -n` on changed shell files,
`./bin/preflight`, and `git diff --check`. For setup or app-install changes,
also run the matching `--dry-run` path. Do not validate with live installs,
account changes, personal restores, or macOS defaults. For a change to a shared
file, run the same checks on a Linux host when you can reach one. Report what
remains unchecked on a real Mac and on Linux.
