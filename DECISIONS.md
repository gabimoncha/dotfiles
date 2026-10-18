# Design decisions

This file records constraints and their reasons. Commands are in
[README.md](README.md), shell usage in [SHELL.md](SHELL.md), and backups in
[MACKUP.md](MACKUP.md).

## One planner, two phases

`bin/setup` owns the dependency plan. `bin/bootstrap` is a compatibility
entrypoint and a function library. Normal, serial, and dry-run runs share the
planner. A dry run executes only the preflight probes.

Preparation stops before bulk packages, personal configuration, authentication,
and restores. The user then signs in to the App Store, reviews App Management,
and restarts the terminal. `--continue` acknowledges that step. No marker or TCC
probe can verify consent or a restart.

Telemetry opt-outs are the one exception to that boundary. Setup exports them
before installers run and reapplies them after packages and restores, also when
an unrelated stage fails.

Homebrew and mise can run at the same time. Resource locks serialize writes to
each package manager across nested helpers. A failed prerequisite blocks only
its consumers. Required failed or deferred stages make setup return nonzero.
Missing optional restore inputs and the explicit mobile opt-out do not.

Scripts own every repeatable step. A coding agent repairs failed stages through
[SETUP-AGENT.md](SETUP-AGENT.md), but it does not replace a script step.
Inference is slower, costs tokens, and can give a different result on each run.

## Ownership

Install GUI apps from the Mac App Store through mas, then supported tools
through mise, then Homebrew. The Brewfile holds Homebrew and App Store entries.
The app manifest adds install status and manual vendor steps. Third-party tap
trust is declared per tap, never disabled globally.

Coding agent CLIs and mise use vendor installers, because self-update needs the
vendor install metadata:

- Codex owns `~/.codex/packages/standalone`.
- Claude Code owns `~/.local/share/claude` and `~/.local/bin/claude`.
- Pi owns `~/.pi/agent`. mise still owns Node and npm, so setup installs Pi
  after the Node inventory.
- OpenCode v2 owns `~/.opencode/bin`.
- Cursor Agent owns `~/.local/share/cursor-agent`. The Cursor GUI is a cask.
- mise lives at `~/.local/bin/mise`. Its pinned installer is checksum-verified.
  The global config sets `self_update.auto`, so mise updates itself.
- The T3 Code nightly cask owns the app and its `~/.t3/bin/t3` launcher, and
  the app updates both. Setup only links Homebrew's `bin/t3` to that launcher,
  and it keeps any other `t3` command.

The global mise config disables the old Codex tool names so that a stale
request cannot reinstall them. `harness update` updates the agent CLIs in
parallel and reports every failure. The mise postinstall hook runs it, and a
zsh helper covers no-op `mise up` runs, where mise fires no hook.

mise owns pnpm before Node, so Corepack wrappers do not shadow it.

### Native Steam installer

Steam is a standalone exception. The Homebrew cask installs an Intel-only
launcher that asks for Rosetta. `bin/install-steam` uses Valve's stable update
manifest to obtain the ARM64 bootstrapper. The app manifest runs that script.
Steam then owns client updates. Existing update-channel settings remain intact.

The script checks the package SHA-256, both launcher architectures, Valve's
signature and Team ID, and Gatekeeper acceptance before replacing the app.
It retains the previous app under `~/.dotfiles-backups/`, removes the old
Homebrew cask without `--zap`, and preserves its `Steam.AppBundle` cache.
Replacement failure restores the app but does not recreate the Homebrew receipt.
Games and account data remain in place. Setup does not install Rosetta or clear
quarantine. Intel-only games can still require Rosetta.

The download method comes from a review of
[steam-arm64-mac at ea9223e](https://github.com/i1rr/steam-arm64-mac/tree/ea9223e092bdb91a8e14b588805258f5e53eab0a).
Setup does not execute that repository's script, which clears quarantine,
forces the beta channel, and deletes the old app backup after copying.

## Xcode and mobile tools

The App Store installs Xcode with `sudo mas get`. After the App Store sign-in
at the checkpoint, it needs no Apple ID prompt and offers only public releases.
mas 7 needs root to install apps. The xcodes CLI is the fallback installer.

The mobile stage runs after every interactive stage, so the long download runs
unattended. It runs before telemetry, so the opt-outs cover the new tools.
`bin/install-mobile-dev` skips finished steps, and `bin/check-mobile-ready` is
its read-only check. `apps/mobile.Brewfile` lists the formulae that need full
Xcode. Mobile setup is on by default. The skip flag does not remove mobile
tools from the common mise inventory.

## Temporary sudo grant

After the first `sudo -v`, setup installs `/etc/sudoers.d/dotfiles-setup`. The
file sets `timestamp_type=global` and `timestamp_timeout=30` for the setup user
and grants no new commands. Stages without a terminal, and an agent shell, can
then use the timestamp that the user created.

The keepalive loop stops when setup exits, so the timestamp expires at most 30
minutes later. The EXIT trap removes the file, also after a failure or a signal.
A killed run can leave the file, and preflight reports it. While the grant is
active, every process of the user can run `sudo` without a prompt. This risk is
accepted for setup on a new Mac.

## GitHub and shell startup

GitHub CLI owns API credentials. Bootstrap installs pinned gh with isolated
configuration. mise gets tokens through `dotfiles-gh-real`, which resolves the
real gh binary without shims or the routing wrapper. API access gates the large
mise install. SSH readiness is a separate check.

Git identity, SSH identity, and API account routing stay separate and local.
Shell startup uses static shims and installed integrations. It never installs
tools or looks up credentials.

## Apple releases and macOS settings

Setup uses public Apple releases only. Preflight stops on an offered macOS
update, an unknown update status, or an apparent prerelease. Setup never
installs OS updates or changes beta enrollment.

App privacy permissions are manual. Setup does not grant TCC consent or edit
its database. Touch ID for sudo and login items are automatic. Login items are
matched by app path. General defaults run once per stamp. Screenshot repair
runs separately, so the stamp cannot block it.

`bin/configure-background-jobs` disables Photos media analysis and Siri voice
training with `launchctl disable`. It runs only when you invoke it. SIP blocks
`bootout` of Apple jobs, so a running job stops at the next login. The list
excludes Siri and Apple Intelligence jobs, which share services on macOS 27. It
also excludes Spotlight, because mas reads installed App Store apps from the
Spotlight index. `--revert` enables the jobs again.

CLIProxyAPI configuration is linked before Homebrew starts its service, and the
service binds to loopback. Neovim is a separate submodule. Its plugins install
at editor startup.

## Portable state

Mackup runs explicit copy-mode backups with a narrow allowlist, and it must not
own repo-managed symlinks. Synology Drive is the primary store. iCloud is a
best-effort fallback. Raycast uses its encrypted export instead of its support
directory.

Codex state uses an age-encrypted allowlist of configuration, memories, and
automation definitions. It excludes authentication, runtime, and database
state. Restore keeps active files and stages conflicts. `--replace` overwrites.
Path checks do not prove that restored executable configuration is safe.

Personal skills come from a reviewed commit and a reviewed skills CLI. They
stay outside the repo and the Codex archive.

## Diagnostics

System Bash and `/usr/bin/ruby` run diagnostics, so a broken managed runtime
does not block recovery. Each run keeps private, sanitized logs. Authentication
output is omitted. INT and TERM stop owned child processes, then release locks.

Git ignores the entire `.local/` directory. When a run starts, the runtime keeps
the latest three run directories and removes older setup logs. This preserves
recent logs for comparison without an unlimited history. Active runs are exempt
until a later run finds that their owner process has stopped. Nested helpers
share their parent run's directory. The limit also includes dry runs and
standalone helpers.

The shell's daily background `git fetch` only notifies. `dotfiles-update`
pulls and reapplies configuration.
