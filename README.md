# dotfiles

Mac setup scripts, tool inventories, and managed configuration.
Start here. [DECISIONS.md](DECISIONS.md) explains the design;
[AGENTS.md](AGENTS.md) contains editing rules.

## Fresh Mac

On the old Mac, run `./bin/prepare-sync` to report inventory drift and
`./bin/file-backup` to save portable state. Complete the Raycast export and
rerun `./bin/file-backup raycast` to mirror it. Confirm the backups are
available before erasing the old Mac. See [backup and restore](MACKUP.md).

Use a public macOS release. Setup stops if the active Apple or MDM catalog
offers a macOS update, the update check is inconclusive, or macOS/Xcode appears
to be a prerelease. Update in System Settings, restart if needed, and retry.
Setup does not install OS updates or change beta enrollment.

```bash
mkdir -p ~/development
git clone https://github.com/gabimoncha/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./bin/setup
```

Run setup as your normal user, not with `sudo`. If Git or setup opens the
Command Line Tools installer, finish it and retry the command.

Each phase asks twice for your password, or Touch ID, near its start. The
first prompt is for `sudo`. The second installs a temporary sudoers file at
`/etc/sudoers.d/dotfiles-setup`, so all your processes share one `sudo`
timestamp. Later stages, and a coding agent shell without a terminal, can then
use `sudo` without a prompt. The timestamp expires after 30 minutes without a
`sudo` command. Setup removes the file when it exits, also after a failure or
Ctrl-C. Preflight reports a file that a killed run left behind. Set
`DOTFILES_SKIP_SUDO_GRANT=1` to skip the grant. Later `sudo` steps then ask in
the terminal.

The first phase installs foundation tools: Homebrew, standalone mise, isolated
GitHub CLI, Codex CLI, Claude Code, Cursor Agent, and OpenCode v2. Pi installs
in the continuation phase, after mise provides Node and npm. Preparation then
exits. Sign in to the App Store app. Review **System Settings
> Privacy & Security > App Management** for the terminal application you use.
Approve access when requested and fully quit/reopen that application as directed.
Return to the repository and continue:

```bash
./bin/setup --continue
```

This flag acknowledges the manual checkpoint; it does not verify permissions
or a terminal restart. Some apps request consent only after installation.

Continuation rechecks foundations, authenticates GitHub, installs packages,
offers restores, and applies configuration. GitHub API access gates the large
mise install. An SSH-only failure does not block it. The mobile stage runs
after every interactive stage and before telemetry. It installs Xcode from the
App Store without an Apple ID prompt.

Setup exports documented telemetry opt-outs before installers run and applies
saved preferences to installed tools. A login job sets the same values for GUI
apps. Reopen apps after setup. `./bin/configure-telemetry [--dry-run]`
reapplies them. The [telemetry guide](apps/telemetry.md) lists every control,
the manual settings, and the tools without an opt-out.

The exact order and dependencies are in [setup-plan.sh](bin/lib/setup-plan.sh).
`bin/bootstrap` delegates to this same planner.

| Option | Effect |
| --- | --- |
| `--dry-run` | Run preflight probes and write private logs; plan provisioning without executing it. Add `--continue` to preview that phase. |
| `--serial` | Wait for each scheduled job before starting the next. |
| `--skip-mobile-dev` | Skip the mobile stage: Xcode, iOS support, Android Studio, and `apps/mobile.Brewfile`. Mobile tools in the common mise inventory still install. |

## Manual completion

- Sign in to Apple/App Store/iCloud and the applications you use.
- Download one provider's backup copies in Finder. The initial checklist reads
  metadata; it neither downloads nor proves backup validity.
- Grant app privacy access manually when a feature needs it. Setup does not
  maintain app permission lists or grant or verify consent. App settings and
  backups do not transfer macOS permission grants.
- Complete eligible restore prompts. Raycast import needs its GUI and password.
  Existing Codex state is preserved for comparison. See [MACKUP.md](MACKUP.md).
- Complete first launch for Android Studio, OrbStack, and vendor apps listed as
  `manual` in [the app manifest](apps/manifest.tsv).
- For the configured Android workflow, install SDK Platform 35, Sources for
  Android 35, Build-Tools and Emulator in Android Studio; create a virtual device.
- Personal skills require a reviewed `skills` CLI and
  `DOTFILES_REVIEWED_SKILLS_REF` set to a reviewed 40-character commit from
  `gabimoncha/skills`. Missing inputs defer the required stage and make setup
  return nonzero. Skills and their lock file stay machine-local.

Missing optional restore prerequisites do not fail a run; an attempted restore
that fails does. Required failed, blocked, or deferred stages return nonzero.
Use `./bin/app-state-doctor` to check managed app links, tmux plugins, Raycast,
Spotlight hotkeys, Touch ID, and disabled background jobs. It is not a complete
installation test.

## Recovery

To let a coding agent repair a failed stage, ask it to follow
[the setup repair guide](SETUP-AGENT.md).
Repair the failed prerequisite. If preparation failed before the permission
handoff, rerun `./bin/setup`. After completing that handoff, use
`./bin/setup --continue`.
Existing links and installations are reused where possible; changed link targets
are backed up under `~/.dotfiles-backups/<timestamp>/`. Homebrew inventory uses
`--no-upgrade`. T3 desktop updates itself. Setup does not update a healthy
mise binary, but mise updates itself because the global config sets
`self_update.auto`.

Each run prints its private `.local/setup-runs/<run-id>/` directory:

- `summary.txt`: outcomes and repair hints.
- `events.jsonl`: stage IDs, prerequisites, timing, status, and failure locations.
- `*.log` and `streams/`: sanitized stage output and original event streams.

Authentication output is omitted. Review logs before sharing them. Logs remain
until manually removed; keep unresolved failures and the latest successful run.
Cancellation stops owned descendants and releases locks. This requires process
inspection access. System Bash and `/usr/bin/ruby` handle diagnostics so a broken
managed runtime does not prevent recovery.

| Command | Use |
| --- | --- |
| `./bin/preflight` | Check macOS updates and repository prerequisites. |
| `./bin/github-bootstrap install-gh` | Repair isolated GitHub CLI acquisition. |
| `./bin/auth-setup --api-only` | Repair GitHub API login. |
| `./bin/auth-setup --ssh-only` | Repair Git identity and SSH access. |
| `./bin/auth-setup --verify-mise` | Check the direct credential helper. |
| `./bin/check-mise-tools` | Probe real installed tools without provisioning. |
| `./bin/install-apps [--dry-run]` | Retry or preview the app manifest. |
| `./bin/install-steam [--dry-run]` | Install Valve's verified ARM64 Steam bootstrapper and replace the old Homebrew cask. |
| `./bin/check-mobile-ready` | Check Xcode, iOS, Android Studio, and `apps/mobile.Brewfile` without changes. |
| `./bin/install-mobile-dev [--dry-run]` | Install or repair Xcode, iOS support, Android Studio, and the mobile formulae. |
| `./bin/sudo-grant --check` | Report a leftover sudo grant; `--enable` and `--disable` change it. |
| `./bin/link-dotfiles` | Reconcile managed links and back up replaced targets. |
| `./bin/setup-tmux` | Install missing TPM plugins and reload a running server. |
| `./bin/configure-app-settings` | Retry automatic login-item setup. |
| `./bin/configure-telemetry [--dry-run]` | Apply documented telemetry opt-outs to installed tools. |
| `./bin/configure-screenshots` | Repair PNG destination preferences at `~/Screenshots`. |
| `./bin/finder-sidebar-favorites` | Retry `development` and `screenshots` favorites. |
| `./bin/configure-sudo-touch-id --check` | Inspect Touch ID for sudo; `--enable`/`--disable` change it. |
| `./bin/configure-background-jobs [--dry-run]` | Disable the user launchd jobs in `macos/disabled-jobs.txt`; `--check` reports drift and `--revert` enables them. |
| `./bin/ensure-mise-standalone --update` | Explicitly update standalone mise. |

Capability resolution and version probes each default to a 10-second deadline;
set `DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS` to override it. The macOS update probe
defaults to 120 seconds (`DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS`).

Use `DOTFILES_SKIP_SUDO_TOUCH_ID=1` to skip Touch ID setup or
`DOTFILES_SKIP_MACOS_DEFAULTS=1` to skip general defaults. Screenshot repair is
separate and still runs. General defaults use the `~/.macos-defaults-applied`
stamp. Apple Watch approval is configured in macOS, not by these scripts.

Setup installs Xcode with `sudo mas get 497799835`. The App Store offers only
public releases. It also updates Xcode automatically, unless you turn off
automatic updates in the App Store settings. Setup does not remove other Xcode
apps. If the App Store cannot install Xcode, download the public `.xip` from
[Apple Developer Downloads](https://developer.apple.com/download/all/), then run:

```bash
xcodes install <public-version> --path "/path/to/Xcode.xip" --select --experimental-unxip
./bin/setup --continue
```

For screenshots, a successful stage proves preference writes, not capture.
Verify a saved file with Shift–Command–3/4. If needed, select `~/Screenshots`
in Shift–Command–5 > Options > Save to. Control copies to the clipboard;
dragging the floating thumbnail can also change where the capture ends up.

### Known limits

These defects are not fixed yet:

- General defaults currently disable display sleep on battery and power.
- If Homebrew reports the Xcode app as too old, setup skips `borders` and does
  not retry it after Xcode installs. Rerun `./bin/setup --continue`.
- A direct `./bin/install-mobile-dev` run omits the macOS update check in
  preflight. It rejects only a prerelease Xcode.
- Raycast backup can create absent provider directories; confirm real cloud
  synchronization. Combined backup can exit zero when neither provider is ready.
- Finder failures can be reported as success; check the resulting sidebar.
- The optional Postgres 18 Compose service uses a legacy data-volume target.

No script proves a fresh-Mac install. See
[the manual checks](SECURITY.md#check-a-fresh-mac-by-hand).

## Ownership and configuration

| Source | Owns |
| --- | --- |
| [Brewfile](Brewfile) | Homebrew formulae, casks, taps and App Store entries. |
| [mise config](home/.config/mise/config.toml) | Runtimes and supported global developer tools. |
| [app manifest](apps/manifest.tsv) | Explicit app installation status and manual vendor steps. |
| [link-dotfiles](bin/link-dotfiles) and `home/` | Managed files and backup-before-replace behavior. |
| [macOS defaults](macos/defaults.sh) | OS preferences. |
| [disabled jobs](macos/disabled-jobs.txt) | Apple user launchd jobs that `bin/configure-background-jobs` disables. |
| [Mackup config](home/.mackup.cfg) | Allowlisted app settings, separate from repo-owned files. |
| `nvim/` | Separate Neovim submodule linked to `~/.config/nvim`; plugins download at first launch. |

Add packages in this order: Mac App Store, then mise, then Homebrew. Coding agent
CLIs and mise itself are explicit standalone-installer exceptions. T3 desktop
uses the nightly Homebrew cask.
Steam uses the verified native installer described below.
See [DECISIONS.md](DECISIONS.md) for the reasons and constraints.

`vscode "publisher.extension"` entries in `Brewfile` select Cursor extensions.
Setup uses Cursor's editor CLI and skips installed extensions.

AeroSpace and Ghostty links wait for their application bundles. Final links
share `home/.codex/AGENTS.md` with Codex and Claude, and merge tracked Codex and
Claude settings without discarding other keys. Replaced files are backed up.
The tracked settings disable [Codex memories](https://learn.chatgpt.com/docs/config-file/config-basic)
with `features.memories = false` and [Claude auto memory](https://code.claude.com/docs/en/env-vars)
with `env.CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1"`. Existing memory files remain.
Start new agent sessions after applying these settings.
`bash ./bin/configure-codex-settings` applies only the Codex settings merge.
It respects `CODEX_HOME` and supports `--dry-run`. Complex representations of
managed TOML keys require a manual edit. The helper preserves the file on failure.
`bash ./bin/configure-claude-settings` applies only the Claude settings merge.

AeroSpace leaves the workspace unchanged for Superwhisper. The main Typeless
window floats on workspace `D`. A separate rule matches Typeless's `Status`
pill by app ID and window title, applies floating layout, and leaves its
workspace unchanged. This rule does not make the pill visible on all workspaces.

CLIProxyAPI binds to `127.0.0.1:49156`. Its tracked configuration is linked into
HOME and Homebrew's `etc/cliproxyapi.conf` before the service starts. Provider
OAuth files remain local and must not be copied into tracked configuration.

[Shell usage](SHELL.md) covers local secrets, GitHub account routing, command
helpers, package runners, and Android paths. [SECURITY.md](SECURITY.md) lists
state that must stay out of Git.

### Steam without Rosetta

The app manifest runs `bin/install-steam`. It downloads the native bootstrapper
from Valve and checks its checksum, ARM64 support, Valve signature, and Gatekeeper
acceptance. A healthy native installation is reused. Steam updates itself after
first launch. The script preserves your existing update channel.

To preview the replacement, run `./bin/install-steam --dry-run`.
Use `./bin/install-steam --verify-download` to download and verify the package
without installing or starting Steam. To replace an existing installation,
quit Steam and run `./bin/install-steam`. Repository preflight must pass first.
If preflight fails, the installer leaves the old app in place. An Intel-only
app will still ask for Rosetta until the replacement completes.
Use `./bin/install-steam --check` to check the installed launchers and signature.
These checks do not prove that first launch or game downloads work.

The installer retains the old app under `~/.dotfiles-backups/` and removes its
Homebrew cask without `--zap`. It preserves games, account data, and the
`Steam.AppBundle` cache. If replacement fails, it restores the old app.
The Homebrew receipt is not restored. Keep the backup until Steam starts correctly.
The download receives a quarantine attribute for macOS first-launch confirmation.
The installer does not install Rosetta or clear quarantine. Intel-only games
can still require Rosetta even when the Steam client runs natively.

## Coding agents

Setup installs the agent CLIs with their vendor installers and reuses healthy
installs. `./bin/ensure-harnesses-standalone` installs or repairs only the
agent CLIs on an existing Mac.

`harness update` updates installed agents in parallel and reports every
failure. `--dry-run` previews the commands, and `--installed-only` skips absent
agents. Each update stops after 30 seconds without new output. Set
`DOTFILES_HARNESS_IDLE_TIMEOUT_SECONDS` to allow a longer idle period.

| Agent | Install source | Update command |
| --- | --- | --- |
| Codex | `https://chatgpt.com/codex/install.sh` with sh | `codex update` |
| Claude Code | `https://claude.ai/install.sh` with Bash | `claude upgrade` |
| Pi | `https://pi.dev/install.sh` with sh; requires Node >=22.19 and npm | `pi update --all` |
| OpenCode v2 | `https://opencode.ai/v2/install` with Bash | `opencode upgrade` |
| Cursor Agent | `https://cursor.com/install` with Bash | `agent update` |

The global mise `postinstall` hook runs `harness update --installed-only`. The
zsh `mise` helper also runs it after a no-op `mise install` or `mise up`, where
mise fires no hook. The global mise config disables the old Codex CLI tool
names, so a stale request cannot reinstall them. The `codex-acp` adapter stays
enabled and still pulls its own npm `@openai/codex` dependency.

The T3 Code nightly app updates itself and its `t3` launcher. Setup links
Homebrew's `bin/t3` to `~/.t3/bin/t3`. Open the app once to create the
launcher. `./bin/link-t3-command [--dry-run]` repairs the link and keeps any
other `t3` command. To adopt an existing app bundle, run
`brew install --cask --adopt t3-code@nightly`.

## Login items and permissions

Setup adds the apps in [the login item list](apps/login-items.txt) as login
items. This can ask for Automation access to System Events. After setup adds
T3 Code Nightly, it removes the `/Applications/Codex.app` login item. Run
`./bin/configure-app-settings --dry-run` to preview the changes.

Privacy permissions are manual for every app. Setup does not write the macOS
consent database, grant TCC access, or clear quarantine.

## Updating and checking changes

`dotfiles-update` runs `git pull --ff-only`, then the continuation plan without
general defaults. It does not upgrade every installed package. The shell's
daily background check only reports new repository commits.
`./bin/prepare-sync` compares the live inventory with the repo and saves a
Brewfile copy under `.sync-backups/`. It does not change tracked inventories.

Before you commit a change, run `bash -n` on the changed scripts,
`./bin/preflight`, and `git diff --check`. Use `./bin/setup --dry-run` or
`./bin/setup --continue --dry-run` to inspect the real preflight and plan.
These commands query Apple's update catalog and write logs.
