# dotfiles

Setup scripts, tool lists, and app settings for the owner's Macs and Linux
hosts. [AGENTS.md](AGENTS.md) has the editing rules and the table of where
each setting lives. [DECISIONS.md](DECISIONS.md) explains the design.

## Layout

```text
mise.toml             file links and shell checkouts for every host
mise.macos.toml       Mac file links and macOS preferences
mise.linux.toml       apt packages and the login shell for Linux
mise.<profile>.toml   one file per machine: pro, air, container, vm
configs/<app>/        the settings files, one folder per app
Brewfile              Homebrew formulae, casks, taps, and App Store apps
apps/                 the app manifest, vendor-installed tools, login items
bin/                  setup and repair scripts
macos/                the macOS defaults script and the telemetry login script
local/                ignored local files; only the examples are tracked
nvim/                 the Neovim config, a separate repository
```

Most files in `configs/` are links in HOME, so an app's change to its file is a
change in this repository. Commit it to share it with your other machines.
Agent settings are the exception. The agents write private paths into
`~/.claude/settings.json` and `~/.codex/config.toml`, so mise merges the keys
of `configs/claude/settings.json` and `configs/codex/config.toml` into them.
`./bin/save-settings` copies your changes back without the private keys. See
[Agent settings](#agent-settings).

## Profiles

| Profile | Machine | Status |
| --- | --- | --- |
| `pro` | MacBook Pro | Set up. |
| `air` | MacBook Air | Not set up yet. Setup stops before it changes anything. |
| `container` | NAS development container | Set up. |
| `vm` | Linux VM, planned on GCP | Not set up yet. Setup stops before it changes anything. |

Save the machine's profile in the ignored `.miserc.local.toml`. A Linux
container without this file uses `container`. `DOTFILES_PROFILE=pro` selects a
profile for one command.

```bash
printf 'env = ["pro"]\n' > .miserc.local.toml
```

## Change a setting

Edit the file in `configs/<app>/`, or the `[dotfiles]` entry in a root mise
file, then preview and apply:

```bash
./bin/link-dotfiles --status
./bin/link-dotfiles --dry-run
./bin/link-dotfiles
```

`bin/link-dotfiles` saves each file that it replaces in
`~/.dotfiles-backups/links-<time>-*/`. `--status` exits with 1 when an entry is
missing or differs. `~/.config/nvim` waits until the `nvim/` submodule is
checked out. `--diff` does not show the content of merged settings, because
those files can hold tokens.

These mise tasks run the same scripts from any folder, for the checkout in
`$DOTFILES_ROOT` or `~/development/dotfiles`: `dot:status`, `dot:diff`,
`dot:apply`, `dot:save`, `setup`, `update`, `packages`, `backup`, `restore`,
and `doctor`. For example, run `mise run dot:apply -- --dry-run`.

### Agent settings

Claude Code and Codex write private data into `~/.claude/settings.json` and
`~/.codex/config.toml`: project paths, hook state, and MCP server details. So
these files are merges, not links. After you change a setting in one of
these apps, save it into the repository and review the result:

```bash
./bin/save-settings --dry-run
./bin/save-settings
git diff configs/claude configs/codex
```

`configs/<app>/sync-keys` marks settings `public` or `private`. A public rule
names one setting, such as `.theme`. A private rule can name a whole section,
such as `.projects`. Each key in the repository file needs a public rule, so
add one when you add a key to `configs/claude/settings.json` or
`configs/codex/config.toml`. `bin/save-settings` saves only the public
settings. It counts the settings that are on neither list and does not save
them. Run `./bin/save-settings --show-new` to list them, add each one to the
list, then save again.

`bin/save-settings` leaves a file unchanged when one of its keys has no public
rule, or when a public setting has become a section or holds a local path, a
credential, or an email address. Its messages never show a value.

On the other machines, `./bin/link-dotfiles` merges the saved keys and keeps
their own private keys. The last save replaces the saved values, so merge
before you change a setting: `bin/save-settings` refuses to save until this
machine has merged the current repository file. A merge never removes a key.
A key that you delete in an app stays on the other machines, and a later save
from one of them puts it back. Delete it on every machine, or mark it private.

## Update a machine

```bash
git pull --ff-only
./bin/link-dotfiles --dry-run
./bin/link-dotfiles
```

The repository's mise commands need mise 2026.10.19. If `bin/repo-mise`
reports an older mise, run `./bin/install-standalone mise` first. After a pull
that moves files, `bin/link-dotfiles` points the old links at the new sources.
It also moves local files from the old layout, such as
`home/.config/local/secrets.zsh`, to `local/`.
`dotfiles-update` pulls, then runs the setup continuation without the general
macOS defaults. It does not upgrade every installed package. The shell's daily
background check only reports new commits. `./bin/prepare-sync` compares the
live inventory with the repository and saves a Brewfile copy under
`.sync-backups/`.

## Set up a new Mac

On the old Mac, run `./bin/prepare-sync` to report inventory drift and
`./bin/file-backup` to save portable state. Complete the Raycast export and
rerun `./bin/file-backup raycast` to mirror it. Confirm the backups are
available before you erase the old Mac. See [backup and restore](MACKUP.md).

Use a public macOS release. Setup stops if the active Apple or MDM catalog
offers a macOS update, the update check is inconclusive, or macOS or Xcode
appears to be a prerelease. Update in System Settings, restart if needed, and
retry. Setup does not install OS updates or change beta enrollment.

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
printf 'env = ["pro"]\n' > .miserc.local.toml
./bin/setup
```

Run setup as your normal user, not with `sudo`. If Git or setup opens the
Command Line Tools installer, finish it and retry the command.

Each phase asks twice for your password, or Touch ID, near its start. The
first prompt is for `sudo`. The second installs a temporary sudoers file at
`/etc/sudoers.d/dotfiles-setup`, so all your processes share one `sudo`
timestamp. Later steps, and a coding agent shell without a terminal, can then
use `sudo` without a prompt. The timestamp expires after 30 minutes without a
`sudo` command. Setup removes the file when it exits, also after a failure or
Ctrl-C. Preflight reports a file that a killed run left behind. Set
`DOTFILES_SKIP_SUDO_GRANT=1` to skip the grant. Later `sudo` steps then ask in
the terminal.

The first phase installs the foundation tools: Homebrew, standalone mise, an
isolated GitHub CLI, Codex CLI, Claude Code, Cursor Agent, and OpenCode v2.
Then it stops:

1. Sign in to the App Store app.
2. In **System Settings > Privacy & Security > App Management**, allow the
   terminal app that runs setup. Approve access when macOS asks.
3. Quit and reopen that terminal app, then continue:

```bash
./bin/setup --continue
```

This flag confirms the manual step. Setup cannot check permissions or the
terminal restart. Some apps ask for consent only after they install.

The continuation checks the foundations again, logs in to GitHub, installs
packages, offers restores, and applies configuration. Pi installs here, after
mise provides Node and npm. GitHub API access gates the large mise install. An
SSH failure alone does not block it. The mobile step runs after every
interactive step and before telemetry. It installs Xcode from the App Store
without an Apple ID prompt.

Setup exports the telemetry opt-outs in
[telemetry.sh](configs/zsh/telemetry.sh) before installers run. A login job,
which mise installs from `mise.macos.toml`, sets the same values for GUI apps.
Reopen apps after setup.
`./bin/configure-telemetry [--dry-run]` applies them again. The
[telemetry guide](apps/telemetry.md) lists every control, the manual settings,
and the tools without an opt-out.

| Option | Effect |
| --- | --- |
| `--dry-run` | Run the preflight check and write private logs. List the other steps without running them. Add `--continue` to preview that phase. |
| `--skip-mobile-dev` | Skip Xcode, iOS support, Android Studio, and `apps/mobile.Brewfile`. Mobile tools in the shared mise list still install. |

[bin/setup](bin/setup) lists the steps in order, and they run one at a time.
The foundation steps are required: preflight, the Command Line Tools, `sudo`,
Homebrew, mise, the GitHub CLI, the links, and in the first phase the agent
CLIs. When one of them fails, setup stops and records the later steps as
blocked. The other steps are marked `--optional`. Each one checks what it
needs, records its failure, and lets the run go on. For example, the mise
inventory runs only after the GitHub check passes. The telemetry step runs
even after a failure.

## Set up a Linux host

Setup also runs on Debian and Ubuntu, for example the NAS container in
[remote development](apps/remote-development.md). Run it as your normal user.
It needs `sudo` for apt and the login shell.

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup --dry-run
./bin/setup
```

Linux runs every step in one run. It has no App Store or restart step.

1. `bin/linux-prerequisites` installs Ruby, Git, and curl with apt. Setup's
   diagnostics run on `/usr/bin/ruby`, as they do on macOS.
2. mise installs the system packages in `mise.linux.toml` and the profile file,
   and makes zsh the login shell.
3. Setup installs the runtime tools, the agent CLIs, and T3
   (`apps/standalone.tsv`), then links the shared files.

Tools marked `os = "macos"` in `configs/mise/global.toml` stay on the Mac.
Entries in `mise.macos.toml` do not load on Linux.

Codex reads one global instructions file. On the container, mise renders
`~/.codex/AGENTS.md` from `configs/agents/instructions.md` and the host rules in
`configs/agents/container.md`. Claude reads the host rules from
`~/.claude/rules/host.md`. The container also turns off the Codex sandbox in
`configs/codex/container.toml`, because its kernel cannot start it.

`DOTFILES_SKIP_GITHUB_AUTH=1 ./bin/setup` defers the GitHub login. mise then
installs tools without a GitHub token. Log in later with `./bin/auth-setup`.
The login asks for the `workflow` scope, so Git can push changes to GitHub
Actions files. On an existing login, `./bin/auth-setup --api-only` adds a
missing scope. Linux uses Git over HTTPS with the GitHub CLI token, not an SSH
key. Agents on a headless host start without an SSH agent and cannot unlock a
protected key.

## Manual completion

- Sign in to Apple, the App Store, iCloud, and the apps you use.
- Download one provider's backup copies in Finder. The first checklist reads
  metadata. It does not download the files or prove that the backup is valid.
- Grant app privacy access by hand when a feature needs it. Setup does not
  grant or check consent, and app settings and backups do not carry macOS
  permission grants.
- Complete the restore prompts. Raycast import needs its GUI and password.
  Existing Codex state is kept for comparison. See [MACKUP.md](MACKUP.md).
- Complete the first launch of Android Studio, OrbStack, and the vendor apps
  marked `manual` in [the app manifest](apps/manifest.tsv).
- For the Android workflow, install SDK Platform 35, Sources for Android 35,
  Build-Tools, and the Emulator in Android Studio, and create a virtual device.
- Personal skills need a reviewed `skills` CLI and
  `DOTFILES_REVIEWED_SKILLS_REF` set to a reviewed 40-character commit of
  `gabimoncha/skills`. Without that commit, setup skips the step. With the
  commit but without the CLI, setup defers the step and returns nonzero. Skills
  and their lock file stay on the machine.

Missing optional restore inputs do not fail a run. A restore that runs and
fails does. A failed, blocked, or deferred step makes setup return nonzero. A
step that you turn off, with `--skip-mobile-dev` or a `DOTFILES_SKIP_*`
setting, does not.
`./bin/app-state-doctor` checks the managed app links, tmux plugins, Raycast,
Spotlight hotkeys, Touch ID, and disabled background jobs. It is not a complete
installation test.

## Recovery

To let a coding agent repair a failed step, ask it to follow
[the setup repair guide](SETUP-AGENT.md). If preparation failed before the
permission step, rerun `./bin/setup`. After that step, use
`./bin/setup --continue`. Setup reuses existing links and installs. Homebrew
installs use `--no-upgrade`. Setup replaces a mise older than the pin, and it
does not update a newer one. Between setup runs, mise updates itself because
the runtime config sets `self_update.auto`. Setup turns that off for its own
run.

Each run prints its private `.local/setup-runs/<run-id>/` folder:

- `summary.txt`: one result line for each step, with a repair hint. Helpers
  add their own lines, such as one for each restore.
- `setup.log`: the output of the steps, with tokens removed. Steps that ask for
  a password or a login print to the terminal only. So do the steps that run
  in the setup shell, such as `brewfiles`.

Git ignores the whole `.local/` folder. Each new run keeps the latest three
run folders and removes older ones. A run that is still active stays until a
later run can remove it. Normal runs, dry runs, and helper commands share this
limit. Copy logs elsewhere before more runs if you need them longer.
Authentication output is omitted. Review logs before you share them.

| Command | Use |
| --- | --- |
| `./bin/preflight` | Check macOS updates and the repository prerequisites. |
| `./bin/link-dotfiles [--status \| --diff \| --dry-run]` | Apply, check, or preview the managed files. |
| `./bin/repo-mise bootstrap repos status` | Check the Oh My Zsh, plugin, and TPM checkouts. |
| `./bin/repo-mise bootstrap macos defaults status` | Compare macOS preferences with `mise.macos.toml`. |
| `./macos/defaults.sh` | Apply macOS preferences, input sources, the Dock, and display sleep. |
| `./bin/github-bootstrap install-gh` | Repair the isolated GitHub CLI install. |
| `./bin/auth-setup --api-only` | Repair the GitHub API login. |
| `./bin/auth-setup --ssh-only` | Repair the Git identity and SSH access. |
| `./bin/auth-setup --git-only` | Linux: repair the Git identity and Git over HTTPS. |
| `./bin/auth-setup --verify-mise` | Check the direct credential helper. |
| `./bin/check-mise-tools` | Check the installed tools without installing any. |
| `./bin/install-apps [--dry-run]` | Retry or preview the app manifest. |
| `./bin/install-standalone status` | Report the vendor-installed tools in `apps/standalone.tsv`. |
| `./bin/install-standalone [NAME...]` | Install or repair those tools. `--dry-run` previews. |
| `./bin/install-steam [--dry-run]` | Install Valve's verified ARM64 Steam bootstrapper. |
| `./bin/check-mobile-ready` | Check Xcode, iOS, Android Studio, and `apps/mobile.Brewfile`. |
| `./bin/install-mobile-dev [--dry-run]` | Install or repair Xcode, iOS support, Android Studio, and the mobile formulae. |
| `./bin/sudo-grant --check` | Report a leftover sudo grant. `--enable` and `--disable` change it. |
| `./bin/setup-tmux` | Install missing TPM plugins and reload a running server. |
| `./bin/configure-app-settings` | Retry the login-item setup. |
| `./bin/configure-telemetry [--dry-run]` | Apply the telemetry opt-outs to installed tools. |
| `./bin/configure-screenshots` | Repair the PNG destination at `~/Screenshots`. |
| `./bin/finder-sidebar-favorites` | Retry the `development` and `screenshots` favorites. |
| `./bin/configure-sudo-touch-id --check` | Inspect Touch ID for sudo. `--enable` and `--disable` change it. |
| `./bin/configure-background-jobs [--dry-run]` | Disable the jobs in `macos/disabled-jobs.txt`. `--check` reports drift, and `--revert` enables them. |

Tool checks and version probes stop after 10 seconds. Set
`DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS` to change that. The macOS update probe
stops after 120 seconds (`DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS`).

Set `DOTFILES_SKIP_SUDO_TOUCH_ID=1` to skip Touch ID setup, or
`DOTFILES_SKIP_MACOS_DEFAULTS=1` to skip the general defaults. Screenshot
repair still runs. The general defaults run once per `~/.macos-defaults-applied`
stamp.

Setup installs Xcode with `sudo mas get 497799835`. The App Store offers only
public releases and updates Xcode automatically, unless you turn that off in
the App Store settings. If the App Store cannot install Xcode, download the
public `.xip` from
[Apple Developer Downloads](https://developer.apple.com/download/all/), then run:

```bash
xcodes install <public-version> --path "/path/to/Xcode.xip" --select --experimental-unxip
./bin/setup --continue
```

A passed screenshot step proves that the preferences were written, not that
captures work. Take a screenshot with Shift-Command-3 or 4 and check the file.
If needed, select `~/Screenshots` in Shift-Command-5 > Options > Save to.

### Known limits

- The general defaults turn off display sleep on battery and on power.
- If Homebrew reports the Xcode app as too old, setup skips `borders` and does
  not retry it after Xcode installs. Rerun `./bin/setup --continue`.
- A direct `./bin/install-mobile-dev` run skips the macOS update check. It
  rejects only a prerelease Xcode.
- Raycast backup can create missing provider folders. Confirm the cloud sync.
  The combined backup can exit zero when neither provider is ready.
- Finder failures can report success. Check the sidebar.
- The optional Postgres 18 Compose service uses a legacy data-volume target.

No script proves a fresh-Mac install. See
[the manual checks](SECURITY.md#check-a-fresh-mac-by-hand).

## Packages and tools

Add packages in this order: the Mac App Store, then mise, then Homebrew. The
agent CLIs and mise itself are vendor-installed exceptions in
`apps/standalone.tsv`. The T3 nightly desktop app is a Homebrew cask. Hex and
Scrawl come from their vendor taps, `anomalyco/tap` and `kitlangton/tap`.
`vscode "publisher.extension"` lines in the Brewfile select Cursor extensions.

`~/.config/mise/mise.lock` links to `configs/mise/mise.lock`. `mise install`
installs the locked versions, and `mise up` writes newer versions into the
tracked file. To add a tool, add it to `configs/mise/global.toml`, then run
`mise lock --global --platform macos-arm64`. After either change, run
`git add configs/mise` and commit the config, the lockfile, and the pipx lock
folder `configs/mise/.mise/locks/`. Commit the lockfile after each `mise up`.
An older lockfile moves the tools back to its versions.

`./bin/install-standalone` installs and repairs the vendor-installed tools and
reuses healthy installs. Run it for one tool, for example
`./bin/install-standalone codex`. `harness update` updates the installed tools
in parallel and reports every failure. `--dry-run` previews the commands, and
`--installed-only` skips absent tools. It skips mise, which updates itself, and
the Linux T3 server, which the T3 app updates. Each update stops after 30
seconds without new output (`DOTFILES_HARNESS_IDLE_TIMEOUT_SECONDS`). The
interactive zsh `mise` helper runs `harness update --installed-only` after a
successful `mise install` or `mise up`. Setup installs missing or broken
agents. It does not update healthy ones.

The T3 Code nightly app updates itself and its `t3` launcher. Setup links
Homebrew's `bin/t3` to `~/.t3/bin/t3`. Open the app once to create the
launcher. `./bin/link-t3-command [--dry-run]` repairs the link and keeps any
other `t3` command. To adopt an existing app bundle, run
`brew install --cask --adopt t3-code@nightly`.

CLIProxyAPI binds to `127.0.0.1:49156`. `bin/link-dotfiles` links its tracked
config into HOME and into Homebrew's `etc/cliproxyapi.conf`. Provider OAuth
files stay local.

`bin/install-steam` replaces the Intel-only Homebrew cask with Valve's ARM64
bootstrapper. It checks the checksum, the ARM64 code, Valve's signature, and
Gatekeeper before it replaces the app, and it keeps the old app under
`~/.dotfiles-backups/`. `--verify-download` checks a download without
installing it, and `--check` checks the installed app. Quit Steam before a
replacement. See [DECISIONS.md](DECISIONS.md#native-steam-installer).

Setup adds the apps in [the login item list](apps/login-items.txt) as login
items. This can ask for Automation access to System Events. After it adds T3
Code Nightly, it removes the `/Applications/Codex.app` login item. Run
`./bin/configure-app-settings --dry-run` to preview the changes. Privacy
permissions are manual for every app.

[SHELL.md](SHELL.md) covers local secrets, GitHub account routing, command
helpers, package runners, and Android paths. [SECURITY.md](SECURITY.md) lists
the state that must stay out of Git.

## Before you commit

Run `bash -n` on the changed scripts, `./bin/preflight`, and `git diff --check`.
Run `./bin/link-dotfiles --dry-run` for a config change, and
`./bin/setup --dry-run` or `./bin/setup --continue --dry-run` for a setup
change. The setup previews query Apple's update catalog and write logs.
