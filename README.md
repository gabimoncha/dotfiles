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

The first phase installs foundation tools: Homebrew, standalone mise, isolated
GitHub CLI, Codex CLI, Claude Code, Cursor Agent, OpenCode v2, and the T3 nightly
CLI. Pi is installed after mise provides Node and npm in the continuation phase.
Preparation then exits. Review **System Settings
> Privacy & Security > App Management** for the terminal application you use.
Approve access when requested and fully quit/reopen that application as directed.
Return to the repository and continue:

```bash
./bin/setup --continue
```

This flag acknowledges the manual checkpoint; it does not verify permissions
or a terminal restart. Some apps request consent only after installation.

Continuation rechecks foundations, authenticates GitHub, installs packages,
offers restores, and applies configuration. API authentication gates broad mise
installation; an SSH-only failure does not invalidate working API access.
Homebrew and mise inventories can overlap, but both finish before foreground
Xcode sign-in. Mobile completion currently runs after restore offers.
The exact order and dependencies are in [setup-plan.sh](bin/lib/setup-plan.sh).
`bin/bootstrap` delegates to this same planner.

| Option | Effect |
| --- | --- |
| `--dry-run` | Run preflight probes and write private logs; plan provisioning without executing it. Add `--continue` to preview that phase. |
| `--serial` | Wait for each scheduled job before starting the next. |
| `--skip-mobile-dev` | Skip explicit mobile stages. Mobile tools in the common mise inventory still install. |

## Manual completion

- Sign in to Apple/App Store/iCloud and the applications you use.
- Download one provider's backup copies in Finder. The initial checklist reads
  metadata; it neither downloads nor proves backup validity.
- Grant app privacy access manually when a feature needs it. Setup does not
  maintain app permission lists or grant or verify consent. App settings and
  backups do not transfer macOS permission grants.
- Complete eligible restore prompts. Raycast import needs its GUI and password.
  Existing Codex state is preserved for comparison. See [MACKUP.md](MACKUP.md).
- Complete first launch for Xcode, Android Studio, OrbStack, and vendor apps
  listed as `manual` in [the app manifest](apps/manifest.tsv).
- For the configured Android workflow, install SDK Platform 35, Sources for
  Android 35, Build-Tools and Emulator in Android Studio; create a virtual device.
- Personal skills require a reviewed `skills` CLI and
  `DOTFILES_REVIEWED_SKILLS_REF` set to a reviewed 40-character commit from
  `gabimoncha/skills`. Missing inputs defer the required stage and make setup
  return nonzero. Skills and their lock file stay machine-local.

Missing optional restore prerequisites do not fail a run; an attempted restore
that fails does. Required failed, blocked, or deferred stages return nonzero.
Use `./bin/app-state-doctor` to check managed app links, tmux plugins, Raycast,
Spotlight hotkeys, and Touch ID. It is not a complete installation test.

## Recovery

Repair the failed prerequisite. If preparation failed before the permission
handoff, rerun `./bin/setup`. After completing that handoff, use
`./bin/setup --continue`.
Existing links and installations are reused where possible; changed link targets
are backed up under `~/.dotfiles-backups/<timestamp>/`. Homebrew inventory uses
`--no-upgrade`. Update T3 desktop through its GUI. Normal setup does not
self-update a healthy mise binary.

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
| `./bin/link-dotfiles` | Reconcile managed links and back up replaced targets. |
| `./bin/setup-tmux` | Install missing TPM plugins and reload a running server. |
| `./bin/configure-app-settings` | Retry automatic login-item creation. |
| `./bin/configure-screenshots` | Repair PNG destination preferences at `~/Screenshots`. |
| `./bin/finder-sidebar-favorites` | Retry `development` and `screenshots` favorites. |
| `./bin/configure-sudo-touch-id --check` | Inspect Touch ID for sudo; `--enable`/`--disable` change it. |
| `./bin/ensure-mise-standalone --update` | Explicitly update standalone mise. |

Capability resolution and version probes each default to a 10-second deadline;
set `DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS` to override it. The macOS update probe
defaults to 120 seconds (`DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS`).

Use `DOTFILES_SKIP_SUDO_TOUCH_ID=1` to skip Touch ID setup or
`DOTFILES_SKIP_MACOS_DEFAULTS=1` to skip general defaults. Screenshot repair is
separate and still runs. General defaults use the `~/.macos-defaults-applied`
stamp. Apple Watch approval is configured in macOS, not by these scripts.

Xcode uses the latest public release and experimental unxip by default;
`DOTFILES_XCODE_EXPERIMENTAL_UNXIP=0` selects regular unxip.
**Other Xcode major versions are removed unless `DOTFILES_KEEP_OLD_XCODES=1`.**
If Apple authentication fails, download the public `.xip` from
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

The review found defects that this documentation cleanup does not repair:

- General defaults currently disable display sleep on battery and power.
- The generated deferred Xcode Brewfile is not consumed after Xcode installation.
- The full direct `install-mobile-dev` path backgrounds Xcode despite its terminal
  input requirement. Direct mobile actions also omit the setup Apple preflight.
  Prefer the main continuation path for now.
- Raycast backup can create absent provider directories; confirm real cloud
  synchronization. Combined backup can exit zero when neither provider is ready.
- Finder failures can be reported as success; check the resulting sidebar.
- The optional Postgres 18 Compose service uses a legacy data-volume target.
- The tracked login profile still contains a machine-specific Codex PATH entry.

Fixture tests do not prove a clean-Mac installation. See the
[remaining real-machine checks](SETUP-SECURITY.md#real-machine-checks-still-required).

## Ownership and configuration

| Source | Owns |
| --- | --- |
| [Brewfile](Brewfile) | Homebrew formulae, casks, taps and App Store entries. |
| [mise config](home/.config/mise/config.toml) | Runtimes and supported global developer tools. |
| [app manifest](apps/manifest.tsv) | Explicit app installation status and manual vendor steps. |
| [link-dotfiles](bin/link-dotfiles) and `home/` | Managed files and backup-before-replace behavior. |
| [macOS defaults](macos/defaults.sh) | OS preferences. |
| [Mackup config](home/.mackup.cfg) | Allowlisted app settings, separate from repo-owned files. |
| `nvim/` | Separate Neovim submodule linked to `~/.config/nvim`; plugins download at first launch. |

Add packages in this order: Mac App Store, then mise, then Homebrew. Coding agent
CLIs and mise itself are explicit standalone-installer exceptions. T3 desktop
uses the nightly Homebrew cask.
See [DECISIONS.md](DECISIONS.md) for the reasons and constraints.

AeroSpace and Ghostty links wait for their application bundles. Final links
share `home/.codex/AGENTS.md` with Codex and Claude, and merge tracked Claude
settings without discarding other keys. Replaced files are backed up.
`bash ./bin/configure-claude-settings` applies only the settings merge.

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

## Updating and validation

Run `./bin/setup --continue` to install the agent CLIs. Healthy vendor installs
are reused. Commands replaced during repair are backed up and restored if the
installer fails. Setup no longer checks for or removes old package-manager
copies; the migration is complete.

`harness update` updates installed agents in parallel and reports every failure:

| Agent | Install source | Update command |
| --- | --- | --- |
| Codex | `https://chatgpt.com/codex/install.sh` with sh | `codex update` |
| Claude Code | `https://claude.ai/install.sh` with Bash | `claude upgrade` |
| Pi | `https://pi.dev/install.sh` with sh; requires Node >=22.19 and npm | `pi update --all` |
| T3 CLI | `https://t3.codes/install.sh` with `T3CODE_CHANNEL=nightly sh` | `t3 update --channel nightly` |
| OpenCode v2 | `https://opencode.ai/v2/install` with Bash | `opencode upgrade` |
| Cursor Agent | `https://cursor.com/install` with Bash | `agent update` |

Use `./bin/harness update` before the managed command is linked, or add
`--dry-run` to preview it. Direct runs return nonzero for missing installations
or failed updates. `--installed-only` skips absent agents during initial setup.
T3 desktop updates through its GUI and is excluded from harness updates.
T3's background service is not restarted by a noninteractive update; run
`t3 service restart` when ready.
Desktop apps and running agents may need to be reopened after an update.

Each harness update stops after 30 seconds without new log output. Output resets
the timer. A timeout stops that update and its child processes; other updates
continue. The summary reports the timeout as a failure and the command returns
nonzero. Set `DOTFILES_HARNESS_IDLE_TIMEOUT_SECONDS` to a positive number of
seconds to allow a longer idle period. This limit applies only to harness updates.

For an existing Mac, run `./bin/link-dotfiles` and
`./bin/ensure-harnesses-standalone` to install or repair only the agent CLIs.
This does not install the T3 desktop cask. Install it with
`brew install --cask --adopt t3-code@nightly`. `--adopt` keeps an existing
nightly app bundle and creates the Homebrew installation record. Homebrew permits
a different bundle version for this cask because it declares `auto_updates true`. Avoid
`--force` when the installed app is newer than the cask's version.

The global mise config disables the old Codex CLI tool names, including
`aqua:openai/codex`, so obsolete project or shell requests cannot reinstall
them. The `npm:@agentclientprotocol/codex-acp` adapter stays enabled. Its npm
package requires a private `@openai/codex` dependency; this is separate from
the old Aqua installation. The adapter supports `CODEX_PATH` to select the
standalone executable, but that does not remove its npm dependency.

The global mise `postinstall` hook invokes `harness update --installed-only`.
The managed zsh helper also covers `mise install`, `mise up`, and
`mise up --local` when no tools change, and prevents a duplicate hook run.
Preview/help commands and failed mise commands do not run the shell updater.
Outside that shell helper, mise runs the native hook only on the paths supported
by mise; a direct no-op `mise up` does not fire the install hook. Open a new
terminal after linking the helper.

Privacy permissions remain manual for every app. No setup helper writes the
macOS consent database, grants TCC access, or clears quarantine. Setup does not
print app permission lists. App settings and backups remain managed; permission
grants are separate. Touch ID for sudo and login-item creation remain automatic.
Login-item creation can request Automation access to System Events; approve
that manually if you want setup to add the login items.

`dotfiles-update` runs `git pull --ff-only`, then the continuation plan with
general defaults skipped. The mise hook updates installed coding agents; other
installed packages are not all upgraded. The
shell's daily background check only reports new repository commits.
`./bin/prepare-sync` compares live inventory and saves a Brewfile copy under
`.sync-backups/`; it does not rewrite tracked inventories.

After changes, run syntax checks on edited scripts and the relevant fixture
suite. To run all repository test scripts:

```bash
(for test in tests/*.sh; do bash "$test" || exit; done)
git diff --check
```

Tests use temporary HOME/config/state directories and fake external actions.
They must not install real packages, use personal backups, or change accounts
and system defaults. Runtime tests need permission to inspect their process
trees. Planner tests retain traces under the ignored setup-runs directory.
Use `./bin/setup --dry-run` or `./bin/setup --continue --dry-run` to inspect the
real preflight and plan; these commands query Apple's update catalog and write logs.
