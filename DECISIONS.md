# Decisions

## Neovim Is a Submodule and a Symlink

`nvim` is a separate GitHub repo so it keeps independent history. The dotfiles repo tracks it as a submodule, and `bin/link-dotfiles` symlinks `dotfiles/nvim` to `~/.config/nvim`.

This keeps fresh-machine bootstrap simple while preserving the separate Neovim repo.

## Homebrew vs mise vs Vendor Apps

Setup has an explicit permission/restart boundary. `./bin/setup` provisions
Command Line Tools, Homebrew and standalone mise (in parallel), isolated gh,
Codex CLI and Cursor Agent, then exits. It does not link the full personal
configuration or start bulk packages, authentication, Xcode, or restores.
The user reviews App Management for their actual terminal application in System
Settings, quits/reopens that application when requested, and runs
`./bin/setup --continue`. Continuation rechecks foundations idempotently and
runs the remaining dependency plan. No marker file claims TCC approval or a
verified terminal restart; the explicit flag acknowledges the manual step.
Some permissions cannot be requested until an app-specific operation occurs.
Never manufacture a destructive operation, edit TCC, or grant broader access
to force a prompt. Both phases use the same planner, logs, and cancellation.

- `Brewfile` owns Homebrew formulae, casks, taps, and VS Code extensions.
- `home/.config/mise/config.toml` owns language runtimes and global dev tools managed by mise.
- `apps/manifest.tsv` tracks cask, formula, and manual/vendor installs that deserve explicit setup status.

Prefer Homebrew casks first. Use vendor/manual fallback only when there is no stable cask or App Store route.

Third-party taps used by setup are explicitly declared with `trusted: true` in
their Brewfiles after review. This persists the repo's approval for later
Homebrew commands while keeping trust checks enabled; setup must not use the
transitional `HOMEBREW_NO_REQUIRE_TAP_TRUST` global bypass.

Codex CLI, Cursor Agent CLI, and `mise` are explicit standalone-installer
exceptions. Codex remote control and app-server updates depend on the
standalone installer-managed path under `~/.codex/packages/standalone`, so
`bin/ensure-codex-standalone` keeps the current standalone install healthy and
removes the Homebrew cask if it exists. Cursor itself remains a Homebrew cask,
but Cursor Agent uses Cursor's official installer because it owns the
`~/.local/share/cursor-agent` runtime and the `agent` / `cursor-agent` commands
under `~/.local/bin`.
`mise` uses the official pinned release installer, verified by SHA-256, at `~/.local/bin/mise`
because package-manager installs do not support `mise self-update`.
`bin/ensure-mise-standalone` keeps existing data, shims, cache, and state in the
normal `mise` locations and removes the Homebrew formula only after the
standalone binary verifies successfully. Normal ensure passes reuse a healthy binary; `--update` is explicit. Homebrew
and mise foundations run concurrently after Command Line Tools readiness.
Interactive shells use static shims and only initialize optional integrations
through verified real installed executables, without provisioning or credential
discovery. Standalone executable paths retain priority.

GitHub authentication has one owner: GitHub CLI. A clean bootstrap configuration
installs only pinned gh. The managed `dotfiles-gh-real` helper resolves a complete
installed gh binary directly on each call, without mise, shims, PATH discovery
or the account-routing wrapper. Mise's credential command calls this helper;
no token is persisted by the helper. API readiness gates broad mise installation,
while SSH readiness is separate. Existing identities remain intact; new SSH
keys require a passphrase and GitHub host keys are verified against published
material.

Git repository identity, GitHub SSH authentication, and GitHub CLI API identity
are selected separately. Account names, emails, directory mappings, SSH aliases,
and key paths stay in ignored machine-local configuration. GitHub CLI has one
global active account for each host, so the managed `~/bin/gh` wrapper reads a
local routing policy and supplies the selected stored token for one command. It
does not export or persist the token, and explicit token environment variables
remain authoritative.

Default setup includes the full mobile development stack because Xcode and iOS platform support dominate fresh-machine time and are safest when started early. Setup prepares `xcodes` and `aria2`, joins Homebrew and mise inventory jobs before the Xcode install so their output cannot obscure Apple sign-in prompts, then finishes iOS platform support and Xcode-dependent formulae after Xcode is selected. `DOTFILES_SKIP_MOBILE_DEV=1` or `./bin/setup --skip-mobile-dev` keeps a lightweight run available.

Xcode installs use only the latest public release. Xcode installs use `xcodes
--experimental-unxip` by default because Xcode archives dominate setup time;
`DOTFILES_XCODE_EXPERIMENTAL_UNXIP=0` keeps the regular unxip path available.
Xcode-sensitive Homebrew formulae stay in `Brewfile` as the source of truth and
are deferred until full Xcode is selected.

Apple tooling uses public releases only. As the first environment gate after
the Darwin check, preflight runs `softwareupdate --list --product-types macOS`
in an English locale. Setup stops when the active Apple or MDM catalog offers
an applicable macOS update. It also stops when the command fails, its output is
not recognized, or macOS or Xcode appears to be a prerelease. This is a
fail-closed check because `softwareupdate` has human-readable output and does
not provide a documented updates-available exit status.

Setup does not claim that the Mac has the newest public release outside its
active catalog. It does not install macOS updates, restart the Mac, change the
software update catalog, or change beta enrollment. The user updates in System
Settings, restarts if required, and reruns `./bin/setup`.

`bin/setup` owns a single dependency planner; `bin/bootstrap` delegates to it.
Homebrew and mise writes are serialized by resource across nested helpers.
Failed prerequisites block consumers while independent work continues. Partial
mise installation still refreshes shims and verifies real executables. Required
failed, blocked or deferred work exits nonzero, including review-gated skills
not yet installed. Optional restores and explicit mobile opt-out do not fail a run. A dry-run traverses this same planner,
executes only labelled preflight probes, and records provisioning as planned.

Setup uses Bash and macOS system utilities before managed tools are ready.
Log redaction, JSON encoding, and bounded tool checks use `/usr/bin/ruby`
directly, so missing mise runtimes cannot prevent recovery. These helpers do
not require Perl or third-party Ruby gems.

Every run keeps private sanitized diagnostics in `.local/setup-runs/<run-id>`:
JSONL lifecycle events, summary, and stage logs. Authentication streams are
omitted by design. Per-process streams preserve concurrent writes and merge
into events.jsonl. Owned descendants are cancelled on INT/TERM, with bounded
escalation, lock cleanup and retained traces. Logs are retained until explicitly
reviewed and removed; no automatic purge obscures a failed run.

Setup preserves display sleep and screen locking, using temporary system
keep-awake only while it runs. NearDrop quarantine stays intact. Security tools
remain optional manual decisions documented in `SETUP-SECURITY.md`.

CLIProxyAPI is installed and started through its `Brewfile` formula. Its
secret-free local server configuration is tracked at
`home/.cli-proxy-api/config.yaml`; `bin/link-dotfiles` links that file into the
home directory and points Homebrew's `etc/cliproxyapi.conf` at it before
`brew bundle` starts the service. Provider OAuth files and credentials remain
machine-local under `~/.cli-proxy-api` and are explicitly excluded from git.

## Mackup Is Copy-Mode and Allowlisted

Mackup is part of the new-Mac workflow, but only through explicit copy-mode
backup/restore helpers under `bin/file-backup` and `bin/file-restore`. The
tracked `home/.mackup.cfg` uses Synology Drive file-system storage and a small
allowlist so Mackup does not try to own files this repo already symlinks. The
backup helper mirrors successful Synology backups to iCloud as a best-effort
secondary copy, and restore falls back to iCloud when the Synology backup is not
available yet.

Raycast stays out of the Mackup allowlist unless Mackup provides a narrow supported profile. The primary Raycast source of truth is the encrypted `.rayconfig` export/import flow, saved under Synology Drive and mirrored to iCloud, which avoids syncing the full app support directory.

## Codex State Uses Encrypted Archives

Global AI skills are sourced from `gabimoncha/skills`, not copied into this
repo. Setup offers skill installation only with a reviewed source commit and an
explicitly installed reviewed `skills` CLI, for Claude Code, Cursor, and Codex. The resulting
`~/.agents/skills` tree and generated `~/.agents/.skill-lock.json` stay
machine-local instead of being symlinked, tracked in Git, or duplicated in the
Codex state archive.

Codex memories and selected user config stay out of git and Mackup. `~/.codex`
contains auth, histories, databases, caches, worktrees, plugin assets, generated
memories, project/workspace state, and connection state in one tree, so the repo
backs up only a curated allowlist through `bin/file-backup codex` as an `age`
passphrase-encrypted archive. Scheduled task definitions are included because
they are useful portable automation intent; raw Codex global app state is not
included because it carries machine/project state that should be fresh per Mac.
Synology Drive is the primary target and iCloud is the secondary copy. Restore
is explicit or prompted during the interactive setup follow-up. On an already
configured Mac, Codex restore preserves active portable state by default and
stages incoming conflicts under `~/.dotfiles-backups`; `--replace` is required
when an archive should intentionally replace current portable state. Standalone
installer packages, app-server state, auth, sqlite databases, histories,
connections, and installation IDs are machine/runtime state and are excluded.

## Explicit Updates With a Daily Notifier

There is no automatic Homebrew upgrade LaunchAgent. The shell runs a non-blocking daily update check and reports when `origin/main` has new commits. Applying updates remains explicit through `dotfiles-update`.

## App Consent and Login Items

Desired privacy states are tracked explicitly in `apps/permissions.tsv`, including
requested disabled states. Setup prints manual instructions before the restart
boundary and after app installation; it does not modify TCC or infer consent.
Login items are added by application path using System Events, preserving existing
items. Missing apps and failed additions remain visible and retryable. GUI apps
not yet present at the preparation checkpoint require consent after installation.
Screenshot destination repair runs independently of the general defaults stamp
so a previous defaults run cannot suppress repair of a changed destination.

Mise owns pnpm directly. Its tool entry precedes Node so Node's bundled Corepack
wrappers cannot shadow it; Node installation does not enable Corepack globally.
Xcodes readiness uses its supported `version` subcommand.

The Xcodes GUI uses mise's GitHub backend by explicit preference, selecting
`XcodesOrg/Xcodes`'s latest `Xcodes.zip` asset. Extraction preserves the app
bundle in mise's install directory; the separate `xcodes` CLI still owns
automated Xcode installation.

Screenshot setup reconciles the working macOS 27 toolbar's `location`,
`location-screenshot`, `location-last`, `target`, and `target-screenshot` keys,
plus PNG format. These are observed implementation details, not a documented
Apple API. Equivalent tilde paths are preserved, readback failures fail the
stage, and separate video settings remain untouched. Both macOS defaults and
setup call the same helper. Capture verification remains manual to avoid
requesting Screen Recording consent during unattended setup.
