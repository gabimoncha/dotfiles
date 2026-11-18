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

macOS shows the App Management prompt only when a process first changes an app
from another developer in `/Applications`, and a new Mac has no such app. So
the last preparation step, `app_management_prompt`, installs the Raycast cask
and writes an extended attribute on the app, then removes it. The prompt then
shows before the terminal restart. The step is optional, and its result does
not prove consent.

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
  itself before interactive commands, without the four-day release delay. It
  skips non-interactive sessions, which are the only use on some hosts, so
  `harness update` runs `mise self-update` first. Setup sets
  `MISE_SELF_UPDATE_AUTO=0`, so the binary does not change during a run.
- The T3 Code nightly cask owns the app and its `~/.t3/bin/t3` launcher, and
  the app updates both. Setup only links Homebrew's `bin/t3` to that launcher,
  and it keeps any other `t3` command.

The global mise config disables the old Codex tool names so that a stale
request cannot reinstall them. `harness update` updates the agent CLIs in
parallel and reports every failure. Setup installs missing or broken agents.
The interactive zsh `mise` helper also updates installed agents. The helper runs the
updater after a successful install or upgrade, including when no mise tools
change. `mise up` leaves pruning to mise (`upgrade.auto_prune`): it removes
the replaced version after 24 hours, so a running program can keep using it
and a broken version can go back. mise skips pin changes, so after
`mise install` without tool names the helper runs `mise prune --tools` for
the tools in the global config. A full prune would also delete project tools
whose untrusted configs mise does not track.

mise owns pnpm and npm. Node.js 26 ships no Corepack, and mise enables
Corepack only with `node.corepack`, so no Corepack wrapper shadows them.

### mise configuration files

The repository root holds the setup config, as mise expects for a bootstrap
project:

- `mise.toml` has the entries for every host.
- `mise.macos.toml` and `mise.linux.toml` have the platform entries. The root
  `.miserc.toml` sets `auto_env`, so mise loads the platform file by itself.
- `mise.macowl.toml`, `mise.macmini.toml`, `mise.air.toml`, and
  `mise.container.toml` are the profiles. The ignored `.miserc.local.toml` selects one, for example
  `env = ["macowl"]`. A profile file can replace an entry of the shared file, as
  the container does for `~/.codex/AGENTS.md`.

Each `[dotfiles]` entry names its source in `configs/<app>/`. An earlier layout
kept one mise file in each app folder. That needed 21 module files, 24 links in
`mise/setup/conf.d/` to load them, and an ignore list so mise did not load the
module files as project config. One file per platform and per profile gives the
same result without those parts.

`~/.config/mise` links to `configs/mise/config/`, the global config folder.
It holds the runtime tool list `config.toml`, each profile's
`config.<profile>.toml`, their locks, and the lock sidecars. The runtime list
also holds the tasks, such as `mise run dot:status`, so they work from every
folder. mise loads `mise/config.toml` from any parent folder as project config,
so the folder is `configs/mise/config/`, not `configs/mise/`. One folder link
replaces a link per file, and a new profile needs no new link.

`bin/repo-mise` runs the pinned mise from the repository root. It loads only
this repository's files: no global or system config, and no config file in a
parent folder. `bin/lib/dotfiles-profile.sh` selects the profile and stops the
deferred Air profile before any write. `repo-mise --global` uses
`configs/mise/config/` as the config folder and sets `MISE_ENV` to the profile,
so it loads the same files as `~/.config/mise`, and no other global config.

A tool for one profile goes in `configs/mise/config/config.<profile>.toml`. The
root profile files cannot hold it: their `[tools]` load only inside this
repository. The folder's `miserc.local.toml` is a tracked link to the ignored
`.miserc.local.toml`, which holds `env = ["<profile>"]`. mise reads it before
any config, sets the environment to the profile, and loads the profile's file.
`bin/link-dotfiles` saves the selected profile in `.miserc.local.toml` when the
file is missing, as on a container. Each profile has its own lock, because
`mise install` prunes lock entries that the loaded config does not name: with
one shared lock, each machine would remove the tools of the other profiles. A
`conf.d` file has this problem, because it shares the global lock. The
environment applies in every folder, so a project file named
`mise.<profile>.toml` also loads. For this reason the Mac profile has the
machine's name, `macowl`, which no other project uses. mise also exports the
profile to every project: tasks and `mise exec` see `MISE_ENV=<profile>`, and
templates see `mise_env`. A project that tests `MISE_ENV` or `mise_env` for
its own environments gets the profile name.

Two settings keep tools working inside the repository. mise refuses an
untrusted file with `[dotfiles]` entries, and then every shim in this folder
fails. The runtime list therefore trusts `~/code/personal/dotfiles`
(`trusted_config_paths`), and `bin/link-dotfiles` trusts the root files for a
checkout in another path. The list also trusts `~/code/work` and
`~/code/client`, which hold the owner's projects. It leaves out
`~/code/contrib` and `~/code/ref`: a mise config can run commands, and those
folders hold other people's repositories. The root `min_version` is soft for the same reason:
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
- It refuses a settings file that is a link. Each merge entry sets
  `permissions = "0600"`, so mise creates a missing settings file as private.
- It keeps mise's output for merges out of the terminal and the setup logs,
  because a parse error can quote the file. `--diff` names the merged files
  without their content.
- Before it replaces `~/.gitconfig`, it copies the Git identity to
  `~/.gitconfig.local`, which the tracked file includes.
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
one setting, and a setting on neither list is counted until you mark it. A
setting can be a list of records, such as T3 model favorites. A record can
also gain new fields, so the save checks every key and text in each record.
On macowl, the source of the shared T3 settings, a login job runs
`bin/autosave-t3-settings` each minute. It calls `bin/save-settings` only when
the live T3 file changed, so a change in T3 reaches the repository without a
manual save. It never commits: the owner reviews each diff before the other
machines get it. mise LaunchAgents have no file watch, so the job checks on a
timer. The save keeps its rule that the machine must first merge the current
source. After a pull, the job reports a failure until `bin/link-dotfiles` runs. Each
key in the source needs a public rule, so that a save cannot delete a key that
nobody listed. The messages of `bin/save-settings` name only paths from the
list and the source, because a key name can be private too. The save converts
the file to JSON, which drops comments, so it rewrites a TOML or YAML source only
when its data changed. It stops when a public setting has become a section or
holds a local path, a credential, or an email address. A `public-home` rule
accepts a path under `$HOME` or `~/`, which is the same on each machine. It
also stops until this machine has merged the current source, so an older live
value cannot replace a newer save from another machine. A merge never removes
a key, so a key deleted in an app stays on the
other machines. The Codex sandbox is not a shared setting. mise 2026.11 refuses
two merges that set one key to different values, so the shared default
`workspace-write` is in `configs/codex/defaults.toml` with `merge = "missing"`.
It sets the key only when the file has none, and it never conflicts. The
container sets `danger-full-access` in its own merge, because its kernel cannot
run the sandbox. `bin/save-settings` never saves a `/defaults` source, and the
sandbox key is private, so one host's value cannot reach the others. The Codex target remains
`~/.codex/config.toml`, independent of `CODEX_HOME`.

The shell checkout declarations are in `mise.toml`, including TPM, which
`bin/setup-tmux` also clones through mise. Setup clones only the missing paths,
and `bin/dotfiles-update` fast-forwards only the current ones with
`--skip-dirty`, because a conflicting checkout stops native repository apply.
Mac preferences are in `mise.macos.toml`; `macos/defaults.sh` keeps the
input-source changes, pmset, and service reloads.

`configs/mise/config/mise.lock` and its sidecar folder
`configs/mise/config/locks/` preserve the global dependency graphs for
macos-arm64 and linux-x64. mise finds the sidecars through the
`~/.config/mise` link. Keep the installed mise at or
above the pin before linking or updating the lockfile. Native package support
does not yet preserve all tap trust, app-presence, sudo, and vendor installer
rules. Those steps stay in scripts. Shell startup activates mise; see
[GitHub and shell startup](#github-and-shell-startup).

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
container is the only Linux host.

- Setup diagnostics stay on `/usr/bin/ruby`. Debian's `ruby` package provides
  it, as the Command Line Tools do on macOS. `bin/linux-prerequisites` installs
  it with Git and curl before the runtime starts, because the runtime needs it.
- mise owns tools. `mise.linux.toml` lists only the system packages
  that mise cannot install, and `mise bootstrap` installs them with apt. Linux
  has no Homebrew and no Nix.
- One runtime tool list serves both systems. Mac-only tools carry
  `os = "macos"`. The platform and profile files add the file entries.
  `configs/mise/config/config.<profile>.toml` adds tools for one profile.
- mise renders Codex's global instructions from the shared rules and the host
  rules in `configs/agents/`. Claude reads the host file from
  `~/.claude/rules/`.
- Linux hosts use Git over HTTPS with the GitHub CLI token. Agents there start
  without an SSH agent, so a protected SSH key would block every push, and an
  unprotected key would add a second credential next to the token.
- Kernel 4.4 on the NAS has no user namespaces, so the agent sandboxes cannot
  run there. The container is the boundary, so its Codex config sets
  `sandbox_mode = "danger-full-access"`.
- The container has no systemd, so mise `[daemons]` (experimental) in
  `mise.container.toml` run T3 and the tokenburnmarket sync daemon under
  pitchfork. The compose command starts and stops them. Each daemon still runs
  a restart loop script, for two gaps in pitchfork 2.34 ("Automatic retries",
  checked in its source). It restarts a daemon only after a failed exit, but
  the systemd units of both services restart after every exit. Its retry
  count also never resets after a good run, so the wait before a retry grows
  up to one hour. With `exec` on the script, pitchfork also waits for the
  script, which gives T3's launcher its 90 seconds to stop. pitchfork signals
  the whole process group, and T3's launcher handles only its first SIGTERM,
  so each script starts its service with `setsid` and sends the one stop
  signal itself. A service in its own group outlives a script that is
  killed, so each script stops earlier copies and their services at its
  start. pitchfork has no watchdog of its own, so the compose command starts
  it again when it dies. The daemons use the fixed namespace `nasbox`, so a
  second checkout cannot start a second copy. The daemons start
  through `bin/container-daemons`, because the supervisor keeps the
  environment of the command that starts it, and `bin/repo-mise` hides the
  global tools.

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

On Linux, the mobile step installs only the Android SDK, so an agent on the
NAS can build Android apps and drive a USB phone. Google publishes the Linux
SDK packages only for x86_64. `ANDROID_HOME` is `~/Android/Sdk`, where the T3
device hub and agent-device also look for `adb`. Android Gradle plugin 9
needs JDK 17 or later.

Both systems get Zulu 17 from mise (`java = "zulu-17"`), not from a Homebrew
cask or apt. Debian 13 has no OpenJDK 17 package. `JAVA_HOME` defaults to
`~/.local/share/mise/installs/java/global`, a link that mise moves to the
installed version, so the path stays the same after an upgrade. Activated
shells get the versioned path from mise. The JDK is not registered with
`/usr/libexec/java_home`, because that needs `sudo` and a link that does not
follow upgrades. Android Studio uses its own JDK.

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

Before its other `sudo` steps, setup installs `/etc/sudoers.d/dotfiles-setup`. The
file sets `timestamp_type=global` and `timestamp_timeout=30` for the setup user
and grants no new commands. Steps without a terminal, and an agent shell, can
then use the timestamp that the user created.

The file makes the terminal's own timestamp invalid, so `sudo` authenticates
two times: for the install and for the shared timestamp. `bin/sudo-grant` reads
the password one time, keeps it in the shell's memory, and gives it to both
`sudo` calls through a pipe. With Touch ID for `sudo`, the script reads no
password, and `sudo` asks two times.

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

### gh extensions

gh installs the gh extensions, through the `dot:gh-extensions` mise task. The
setup step `gh_extensions` runs the task after the GitHub login. Then
`gh extension list` shows each extension's repository and version, and
`gh extension upgrade --all` updates them.

The mise `github:` backend can install the binaries, with lock checksums and
the four-day release delay. But gh runs an extension only from its own
extensions folder, not from PATH. The mise install then needs a link script in
a postinstall hook, and gh sees a local extension that `gh extension upgrade`
skips. The cost of the gh install: the extensions do not get the release
delay or lock checksums.

Every shell activates mise: `configs/zsh/mise-activate.zsh` for zsh, and
`configs/bash/mise-activate.bash` for the bash commands of Pi. Agents run
commands with `zsh -c` (OpenCode, Claude), `zsh -lc` (Codex), `zsh -ilc`
(Cursor), or `bash -c` (Pi). So zshenv activates mise for `zsh -c`, the end of
zprofile for `zsh -lc`, interactive.zsh for an interactive shell, and Pi's
`shellCommandPrefix` for bash. A command then gets the tool versions of its
folder without `mise exec`. A tool starts directly, not through a shim that
starts the 135 MB mise binary each time. Activation does not add the shims folder
to PATH (`activate_shims = false`). Activation costs about 0.2 s
for each zsh, and it skips a shell that `mise exec TOOL@VERSION` or a mise
task started. It never installs tools or looks up credentials.

On every host, `~/.bash_profile` links to `configs/bash/bash_profile`. A login
bash (`bash -l`) reads that file, which reads `~/.profile` and then activates
mise. `~/.profile` stays a local file, because hosts add their own lines to it.
Debian's `/etc/profile` sets a new PATH for a login bash, so without the file
`bash -l` lost the mise tools of its parent shell. macOS `path_helper` keeps
the inherited PATH, but a login bash that starts with a clean environment has
no mise tools there either. A `bash -c` and an interactive bash keep the PATH
of their parent shell.

Claude Code gets the mise shims on PATH from a wrapper. Claude Code writes a
shell snapshot one time, when a session starts, and each Bash tool command
sources it after zshenv. The last line of the snapshot sets PATH to the PATH
of the Claude process, and that line replaces the PATH of the activation. With
`mise/installs` folders on the PATH of the Claude process, a command gets the
versions of the folder where Claude started. In another folder, project tools
are not found, and shared tools have the wrong version.

`configs/claude/claude` is linked at `~/bin/claude`, ahead of the vendor
command `~/.local/bin/claude`. It puts `~/bin`, `~/.local/bin`, and the shims
folder first on PATH, removes the `mise/installs` folders, and starts the
vendor command with `exec`. A shim finds the version for the current folder
each time a command runs, so the recorded PATH is correct in every folder. The
mise documentation gives the same rule: activation for the shell that you type
into, shims for programs that do not start from it. T3 Code starts `claude` by
name, so it starts the wrapper too. Inside `mise exec TOOL@VERSION` or a mise
task, the wrapper keeps PATH.

Shells keep activation when `CLAUDECODE` is set. Activation runs in zshenv
before the snapshot, so a command has the `[env]` variables and the
`[shell_alias]` aliases of its folder. The snapshot replaces only PATH. After
a `cd` in a command, the activation hook sets PATH for the new folder.

The wrapper removes the `mise/installs` folders. Shims ahead of them are not
sufficient. By default, when the version for a folder is not installed, a shim
runs the next executable of that name on PATH. An install folder behind the
shims then gives the global version with no error. The global config sets
`not_found_system_fallback = false`, so the shim stops with
`Tool not installed for shim` and does not run a Homebrew or system
executable of that name either. Each executable in those folders has a shim, so no command is
lost.

A shim call takes about 0.08 s more than a direct call, and `which node`
prints the shim: `mise which node` prints the tool. `bin/install-standalone`
and `harness update` use the path `~/.local/bin/claude` from
`apps/standalone.tsv`, and `claude update` and the automatic update change
only that path. None of them reads or changes the wrapper.

The snapshot drops each function whose name starts with one underscore. So a
helper that a function in `configs/zsh/` calls when it runs has a name with
two underscores.

`npx` and `px` are executables in `~/bin`: two links to
`configs/npx/npx`. They were shell functions that only interactive zsh
loaded, so Codex, OpenCode, and Pi ran the npx of npm. `~/bin` is first on
PATH in every shell, so each agent now gets them, in zsh and in bash. So does
a command that a script, a package manager, or an MCP config starts, which a
shell function cannot reach. `npx` and `px` run the package manager that mise
selects for the folder (`[settings.npm] package_manager`): `bunx` for bun,
`sfw pnpm exec` or `sfw pnpm dlx` for pnpm, and `aubx` for aube.

A caller that had the npx of npm gets these differences:

- `bunx` does not have `-c` (`--call`). `-y`, `-p`, `--package`,
  `--no-install`, `-q`, and `--` work.
- In a folder whose mise config selects `npm` or `yarn`, `npx` stops with
  exit status 1. The error names the supported package managers and
  `sfw npm exec -- <package>`, which runs the npx of npm through Socket
  Firewall.
- Each call starts `mise settings get` and takes about 0.02 s more.

`mise exec` and a mise task put the tool folders ahead of `~/bin`, so `npx`
there is the npx of npm.

Aliases for every shell are in `[shell_alias]` in the global mise config.
Two groups stay in `configs/zsh/aliases.zsh` for interactive zsh only. Aliases
that replace a standard command (`cat`, `ls`, `grep`, `tree`) stay there,
because agents write flags for the standard command. The Socket Firewall
aliases (`npm`, `pnpm`, `cargo`, ...) stay there, because `sfw` adds about
0.4 s and a node process to each call. Agents keep the release-age delays of
mise, Bun, and pnpm. Current behavior differs for Claude Code: its snapshot
shell sources `~/.zshrc`, so Claude Code shells have both groups too.

A login job on each Mac logs free memory and the busiest processes each minute
into `~/.local/state/dotfiles/process-log/`, for 7 days. It keeps process names
and parent names, never command arguments.

## Apple releases and macOS settings

Setup uses public Apple releases only. Preflight stops on an offered macOS
update, an unknown update status, or an apparent prerelease. Setup never
installs OS updates or changes beta enrollment. `--allow-macos-beta` is the one
exception: the user opts in for a run on a macOS beta build. It does not cover a
pending update or a prerelease Xcode.

App privacy permissions are manual. Setup does not grant TCC consent or edit
its database. Touch ID for sudo and login items are automatic. mise owns the
login items, the Dock apps, and the Touch ID block in `/etc/pam.d/sudo_local`.
Login items are matched by app path, and mise leaves undeclared ones alone. The
Dock list is exact: mise adds, removes, and orders the pinned apps.
`bin/configure-sudo-touch-id` keeps the check that Apple's `sudo` file includes
`sudo_local`, and `--disable`, which mise does not have. General defaults run
once per stamp. Screenshot repair
runs separately, so the stamp cannot block it.

Live Text is off in the global defaults (`AppleLiveTextEnabled`). Without it,
Safari makes the text in a paused video selectable, and a click selects text
instead of playing the video.

## Neovim config

The Neovim config is in `configs/nvim/`, and `~/.config/nvim` links to that
folder. Its plugins install at editor startup. The config was a Git submodule
from `gabimoncha/nvim` until the nvim commit `c68cade`. The submodule caused
these problems:

- Each plugin change needed two commits: one in nvim, and a commit in dotfiles
  that moved the submodule pointer.
- `git submodule update --init nvim` refused a checkout when `lazy-lock.json`
  was modified, also when its content matched the target commit.
- The hk hooks found the dotfiles `hk.pkl` from inside `nvim/` and reformatted
  `lazy-lock.json`.

lazy.nvim writes `lazy-lock.json` in its own format. `hk.pkl` excludes
`configs/**/*.json` from the format steps, so the hooks keep that format.

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

## Mac profiles

macowl is the personal MacBook Pro. The Mac mini is a development machine that
you use through SSH and sometimes at its monitor. The shared Mac lists hold
what both need: the root `Brewfile`, `apps/manifest.tsv`,
`mise.macos.toml`, and the Mac tools in
`configs/mise/config/config.toml`. An entry for one Mac goes in that
profile's files. A shared list with one extra file per profile keeps one
place for each app. A complete list per profile would repeat most entries, and
the two copies would drift.

The Mac mini has no dictation apps, no Synology Drive, and no Mackup, so setup
restores only the Raycast export there. Its Raycast exports go to iCloud Drive.
It runs the T3 server as a login service, with no desktop app. The T3 server,
tokenburnmarket, and the process log are login jobs, and they start only in a
user session. So the Mac mini logs in automatically after a restart, and macOS
allows automatic login only with FileVault off. `bin/configure-remote-access`
stops and reports when FileVault is on. It never turns FileVault off, because
that choice gives a person at the machine your session.

A login job then locks the screen, so the session exists but the desktop needs
the password. `bin/lock-screen` calls `SACLockScreenImmediate` from the private
login framework. No public command locks the screen without a dependency on
the display state, and the Mac mini often has no display. An Apple update can
remove the function; the screen then stays unlocked after a start, and nothing
else breaks.

## Portable state

Mackup runs explicit copy-mode backups with a narrow allowlist, and it must not
own repo-managed symlinks. Synology Drive is the primary store. iCloud is a
best-effort fallback. Raycast uses its encrypted export instead of its support
directory.

Codex state uses an age-encrypted allowlist of configuration, memories, and
automation definitions. It excludes authentication, runtime, and database
state. Restore keeps active files and stages conflicts. `--replace` overwrites.
Path checks do not prove that restored executable configuration is safe.

### Agent skills

The repository tracks the installed skill folders in `configs/agents/skills/`
and the `skills` CLI lock in `configs/agents/skill-lock.json`. A new machine
gets every skill with `git pull` and `./bin/link-dotfiles`, with no network
install and no reinstall step in setup. A list of sources would be smaller,
but each machine would then install whatever the sources hold that day, and
local edits to a skill would not reach the other machines.

The cost is churn. The CLI writes `updatedAt` for each update and
`lastSelectedAgents` for each install, so the lock changes even when no skill
does. The owner accepts that and commits after each `skills add`, `update`,
or `remove`.

`~/.agents/skills` and `~/.agents/.skill-lock.json` are folder and file links
into the repository. The CLI deletes and rewrites a skill folder inside the
linked folder, and it writes the lock with a plain file write, which follows
the link. It reads the lock from `$XDG_STATE_HOME/skills/` instead when
`XDG_STATE_HOME` is set, and no host sets it.

Claude Code reads only `~/.claude/skills/`. A glob entry,
`"~/.claude/skills/*"`, makes one link for each skill and leaves the other
items in that folder alone, such as Claude Code's `synced/` and `.trash/`.
mise does not delete a glob link when its skill goes away. A
`[bootstrap.hooks.post-dotfiles]` hook removes the broken links that point into
a skills folder. The hook never fails, because `bin/link-dotfiles` undoes the
apply when mise fails. `symlink-each` mode would make real folders with a link
for each file, and the CLI deletes those folders when it updates a skill.

Every host gets the same skills, including the container. At the first apply,
`bin/link-dotfiles` moves each machine's old `~/.agents/skills` folder and lock
to its link backup, so a skill that the repository lacks stays there. `creative-act` stays out because its source has no license, and this
repository is public. `licenses/skills/` keeps the license of each source.

The skills stay out of the Codex archive.

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
