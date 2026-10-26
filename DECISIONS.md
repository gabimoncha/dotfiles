# Design decisions

This file records constraints and their reasons. Commands are in
[README.md](README.md), shell usage in [SHELL.md](SHELL.md), and backups in
[MACKUP.md](MACKUP.md).

## One step list, two phases

`bin/setup` runs the steps in order, one at a time. The step functions are in
`bin/lib/setup-steps.sh`, and `bin/bootstrap` only calls `bin/setup`. A dry run
executes only the preflight check.

Preparation stops before bulk packages, personal configuration, authentication,
and restores. The user then signs in to the App Store, reviews App Management,
and restarts the terminal. `--continue` acknowledges that step. No marker or TCC
probe can verify consent or a restart.

Telemetry opt-outs are the one exception to that boundary. Setup exports them
before installers run and reapplies them after packages and restores, also when
another step fails. mise installs the login job that sets them for GUI apps,
from `[bootstrap.macos.launchd.agents]` in `mise.macos.toml`.

An earlier planner tracked dependencies and ran Homebrew and mise at the same
time. One list in order is easier to read and to repair, and a rerun skips
finished work. A first install is slower. The foundation steps are required:
when one fails, setup stops and records the later steps as blocked. The other
steps are optional, because each one checks what it needs. So a failed GitHub
check stops the mise install, which needs the API access, but not the Homebrew
inventory or the restores. Resource locks still serialize writes to each
package manager across nested helpers. A failed, blocked, or deferred step
makes setup return nonzero. Missing optional restore inputs and the steps that
the user turns off do not.

Scripts own every repeatable step. A coding agent repairs failed steps through
[SETUP-AGENT.md](SETUP-AGENT.md), but it does not replace a script step.
Inference is slower, costs tokens, and can give a different result on each run.

## Ownership

Install GUI apps from the Mac App Store through mas, then supported tools
through mise, then Homebrew. The Brewfile holds Homebrew and App Store entries.
The app manifest adds install status and manual vendor steps. Third-party tap
trust is declared per tap, never disabled globally.

Coding agent CLIs and mise use vendor installers, because self-update needs the
vendor install metadata. `apps/standalone.tsv` lists them with their commands,
install folders, installers, and update commands. `bin/install-standalone` is
the one script that installs, updates, and checks them; vendor quirks stay in
small cases in that script:

- Codex owns `~/.codex/packages/standalone`.
- Claude Code owns `~/.local/share/claude` and `~/.local/bin/claude`.
- Pi owns `~/.pi/agent`. mise still owns Node and npm, so setup installs Pi
  after the Node inventory.
- OpenCode v2 owns `~/.opencode/bin`.
- Cursor Agent owns `~/.local/share/cursor-agent`. The Cursor GUI is a cask.
- mise lives at `~/.local/bin/mise`. Its pinned installer is checksum-verified.
  Setup replaces a mise older than the pin, because the repo's mise files need
  that release. The global config sets `self_update.auto`, so mise updates
  itself between setup runs. Setup sets `MISE_SELF_UPDATE_AUTO=0`, so the binary
  does not change during a run.
- The T3 Code nightly cask owns the app and its `~/.t3/bin/t3` launcher, and
  the app updates both. Setup only links Homebrew's `bin/t3` to that launcher,
  and it keeps any other `t3` command.

The global mise config disables the old Codex tool names so that a stale
request cannot reinstall them. `harness update` updates the agent CLIs in
parallel and reports every failure. Setup installs missing or broken agents.
The interactive zsh `mise` helper also updates installed agents. The helper runs the
updater after a successful install or upgrade, including when no mise tools
change. After `mise up`, or `mise install` without tool names, the helper first runs
`mise prune --tools` for the tools in the global config. A full prune would
also delete project tools whose untrusted configs mise does not track. mise's own upgrade prune waits 24 hours, so a broken version can
go back, and it skips pin changes. Here the old version goes at once; going
back means a new install.

mise owns pnpm before Node, so Corepack wrappers do not shadow it.

### mise configuration files

The repository root holds the setup config, as mise expects for a bootstrap
project:

- `mise.toml` has the entries for every host.
- `mise.macos.toml` and `mise.linux.toml` have the platform entries. The root
  `.miserc.toml` sets `auto_env`, so mise loads the platform file by itself.
- `mise.pro.toml`, `mise.air.toml`, `mise.container.toml`, and `mise.vm.toml`
  are the profiles. The ignored `.miserc.local.toml` selects one, for example
  `env = ["pro"]`. A profile file can replace an entry of the shared file, as
  the container does for `~/.codex/AGENTS.md`.

Each `[dotfiles]` entry names its source in `configs/<app>/`. An earlier layout
kept one mise file in each app folder. That needed 21 module files, 24 links in
`mise/setup/conf.d/` to load them, and an ignore list so mise did not load the
module files as project config. One file per platform and per profile gives the
same result without those parts.

`~/.config/mise/config.toml` links to `configs/mise/global.toml`, the runtime
tool list. mise loads `mise/config.toml` from any folder as project config, so
the source keeps the name `global.toml`. The runtime list also holds the tasks,
such as `mise run dot:status`, so they work from every folder.

`bin/repo-mise` runs the pinned mise from the repository root. It loads only
this repository's files: no global or system config, and no config file in a
parent folder. `bin/lib/dotfiles-profile.sh` selects the profile and stops the
deferred Air and VM profiles before any write. `repo-mise --global` loads only
the runtime tool list.

Two settings keep tools working inside the repository. mise refuses an
untrusted file with `[dotfiles]` entries, and then every shim in this folder
fails. The runtime list therefore trusts `~/development/dotfiles`
(`trusted_config_paths`), and `bin/link-dotfiles` trusts the root files for a
checkout in another path. The root `min_version` is soft for the same reason:
a hard minimum stops every shim in this folder while an older mise is
installed. `bin/repo-mise` still requires the pinned release.

mise applies the links, copies, templates, and merges. It refuses to put a
link where a real file is, and one refused entry stops the whole apply.
`bin/link-dotfiles` handles what mise does not:

- It checks the whole selection with a dry run, and renders the templates,
  before it changes a file. It stops when the folder of a target resolves into
  this repository or out of HOME, and when `~/.dotfiles-backups` or
  `~/.gitconfig.local` is a link, because private data would go there.
- It moves a real file at a link target to `~/.dotfiles-backups/links-*/`. It
  copies a file that mise will overwrite or merge into, and it keeps an old
  link as a link. If mise then stops, it moves the files back.
- It refuses a settings file that is a link, and it creates a missing settings
  file with mode 0600. mise would use 0644.
- It keeps mise's output for merges out of the terminal and the setup logs,
  because a parse error can quote the file. `--diff` names the merged files
  without their content.
- Before it replaces `~/.gitconfig`, it copies the Git identity to
  `~/.gitconfig.local`, which the tracked file includes.
- It skips `~/.config/nvim` while the `nvim/` submodule is empty.
- It removes links that older versions made, only while they point into this
  repository. It moves local files from the old layout, such as
  `mise/setup/miserc.local.toml`, to their new place.
- On a Mac, it runs `bin/link-t3-command`. That step and the telemetry login job
  in `bin/configure-telemetry` run only when `$HOME` is the account's home
  folder, so a test with a temporary HOME cannot change them.

Agent and T3 settings remain regular files because the apps rewrite them and
write private data into them: project paths, hook state, and MCP server
details. A link would publish that data with the next commit. A Git filter
cannot fix that either: each pull would overwrite the live file and lose the
machine's own keys. So the sync has two directions. `bin/link-dotfiles` merges
the keys of `configs/claude/settings.json`, `configs/codex/config.toml`, and
`configs/t3/settings.json` into the live files and keeps every other key.
`bin/save-settings` copies the settings that `configs/<app>/sync-keys` marks
public back into the source.
mise 2026.10.18 cannot do this step: `mise dot add` refuses a merged file, and
`mise dot track` saves whole files, private keys included, to its own history. A
list of public settings, not a list of private ones, decides what is saved:
an ordinary key can hold a credential, such as an authorization header, and a
section can gain new fields, such as exporter headers. So a public rule names
one setting, and a setting on neither list is counted until you mark it. Each
key in the source needs a public rule, so that a save cannot delete a key that
nobody listed. The messages of `bin/save-settings` name only paths from the
list and the source, because a key name can be private too. The save converts
the file to JSON, which drops comments. It stops when a public setting has
become a section or holds a local path, a credential, or an email address. It
also stops until this machine has merged the current source, so an older live
value cannot replace a newer save from another machine. A merge never removes
a key, so a key deleted in an app stays on the
other machines. The container adds its sandbox key in a second merge, and the
Codex list keeps that key private. The Codex target remains
`~/.codex/config.toml`, independent of `CODEX_HOME`.

The shell checkout declarations are in `mise.toml`. The existing missing-path
filter remains because a conflicting checkout stops native repository apply.
Mac preferences are in `mise.macos.toml`; `macos/defaults.sh` keeps the
input-source changes, Dock pruning, pmset, and service reloads.

`configs/mise/mise.lock` and its sidecar folder `configs/mise/.mise/locks/`
preserve the global dependency graphs for macos-arm64 and linux-x64. mise finds
the sidecars next to the real lockfile, through the `~/.config/mise/mise.lock`
link. Keep the installed mise at or
above the pin before linking or updating the lockfile. Native package support
does not yet preserve all tap trust, app-presence, sudo, and vendor installer
rules. Those steps stay in scripts. Shell startup keeps static shims and zsh
aliases.

After a pull that moves sources, the old HOME links are broken until
`./bin/link-dotfiles` runs. It points them at the new sources.

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

## Linux hosts

`bin/setup` runs a one-phase Linux plan on Debian and Ubuntu. The NAS
container is the first host. A GCP VM is the next one.

- Setup diagnostics stay on `/usr/bin/ruby`. Debian's `ruby` package provides
  it, as the Command Line Tools do on macOS. `bin/linux-prerequisites` installs
  it with Git and curl before the runtime starts, because the runtime needs it.
- mise owns tools. `mise.linux.toml` lists only the system packages
  that mise cannot install, and `mise bootstrap` installs them with apt. Linux
  has no Homebrew and no Nix.
- One runtime tool list serves both systems. Mac-only tools carry
  `os = "macos"`. The platform and profile files add the file entries.
- mise renders Codex's global instructions from the shared rules and the host
  rules in `configs/agents/`. Claude reads the host file from
  `~/.claude/rules/`.
- Linux hosts use Git over HTTPS with the GitHub CLI token. Agents there start
  without an SSH agent, so a protected SSH key would block every push, and an
  unprotected key would add a second credential next to the token.
- Kernel 4.4 on the NAS has no user namespaces, so the agent sandboxes cannot
  run there. The container is the boundary, so its Codex config sets
  `sandbox_mode = "danger-full-access"`. A VM with a current kernel can use
  the sandboxes.

## Xcode and mobile tools

The App Store installs Xcode with `sudo mas get`. After the App Store sign-in
at the checkpoint, it needs no Apple ID prompt and offers only public releases.
mas 7 needs root to install apps. The xcodes CLI is the fallback installer.

The mobile step runs after every interactive step, so the long download runs
unattended. It runs before telemetry, so the opt-outs cover the new tools.
`bin/install-mobile-dev` skips finished steps, and `bin/check-mobile-ready` is
its read-only check. `apps/mobile.Brewfile` lists the formulae that need full
Xcode. Mobile setup is on by default. The skip flag does not remove mobile
tools from the common mise inventory.

The Android SDK has one location, `ANDROID_HOME`. The mobile step downloads
Google's Command Line Tools at a pinned SHA-256 into a temporary folder. That
copy of `sdkmanager` accepts the licenses and installs the packages in
`apps/android-sdk.txt`, including its own `cmdline-tools;latest`. The
`android-commandlinetools` cask is not used, because its `sdkmanager` uses the
cask folder as a second SDK root. Android Studio uses the same SDK, and builds
from the command line need no Studio first launch.

From Command Line Tools 23.0, `sdkmanager` downloads the Android CLI into
`~/.android` and runs through it. That CLI sends usage metrics unless it gets
`--no-metrics`. The linked `~/.androidrc` sets that option for every run, and
the mobile step stops before `sdkmanager` when the option is missing.

## Temporary sudo grant

After the first `sudo -v`, setup installs `/etc/sudoers.d/dotfiles-setup`. The
file sets `timestamp_type=global` and `timestamp_timeout=30` for the setup user
and grants no new commands. Steps without a terminal, and an agent shell, can
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

Neovim is a separate submodule. Its plugins install at editor startup.

## NAS agent proxy

CLIProxyAPI uses the official image in a separate NAS Compose project. Docker
owns installation, restarts, and logs. Separate mounts keep provider OAuth
files outside `nasbox`, where coding agents have passwordless sudo. Proxy
updates do not require a restart of the development container.

The Compose example publishes only on NAS loopback and joins the existing
development network for `nasbox` clients. The NAS's existing Tailscale Serve
provides remote HTTPS access. Dotfiles keeps public provider
settings and deployment examples. Private client URLs, keys, and the live
server configuration stay outside Git. Codex uses `env_key` for its proxy key.
T3's shared launch arguments select the proxy. The global Codex provider stays
`openai` so the desktop app can use ChatGPT sign-in. T3 shares only the default
Codex instance's driver and launch arguments; its other state stays local.
Claude uses private native `env` settings.
See [NAS agent proxy](apps/remote-development.md#nas-agent-proxy).

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
