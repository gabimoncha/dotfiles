# Design decisions

Operational commands belong in [README.md](README.md), shell usage in
[SHELL.md](SHELL.md), and migration instructions in [MACKUP.md](MACKUP.md).
This file records constraints and their reasons, not a second setup plan.

## One planner, two phases

`bin/setup` owns the dependency plan; `bin/bootstrap` is a compatibility
entrypoint and function library. Preparation stops before bulk packages,
personal configuration, authentication, and restores so the user can review
App Management and restart the terminal. `--continue` acknowledges that step;
no marker or TCC probe claims to verify consent or restart.

Homebrew and mise foundations overlap after CLT readiness. Their inventories
can overlap later. Both inventories finish before Xcode sign-in so background
output does not obscure credentials. Resource locks serialize writes to each
package manager across nested helpers. The planner is shared by normal,
serial, and dry-run execution; dry-run executes only preflight probes.

Failed prerequisites block consumers while independent work continues. Partial
mise installation still reshims and checks real tools. Required deferred work,
including unreviewed personal skills, returns nonzero. Missing optional restore
prerequisites and explicit mobile opt-out do not fail the run.

## Ownership

Prefer Mac App Store apps via mas, then supported runtimes/tools via mise,
then Homebrew. Brewfile stores Homebrew and App Store entries; the app manifest
adds explicit status and manual vendor steps. Third-party tap trust is declared
per tap; never disable trust checks globally.

Vendor coding-agent installers and mise are exceptions:

- Codex owns `~/.codex/packages/standalone` for installer/app-server integration.
- Claude Code owns `~/.local/share/claude` and `~/.local/bin/claude`.
- Pi owns its managed install under `~/.pi/agent`; mise still owns Node and npm.
- T3 CLI owns `~/.t3/runtime/versions` and `~/.local/bin/t3`, always on nightly.
  Its desktop app uses `t3-code@nightly` in Homebrew.
- OpenCode v2 owns `~/.opencode/bin` through its v2 installer.
- Cursor Agent owns `~/.local/share/cursor-agent` and local command links;
  Cursor's GUI stays a Homebrew cask.
- mise lives at `~/.local/bin/mise` to support explicit self-update. Its pinned
  installer is checksum-verified; tool data stays in normal mise directories.

Reuse healthy standalone binaries and preserve settings during repair. The
package-manager migration is complete; agent setup no longer scans for old copies,
uninstalls packages, or writes migration receipts. Agent CLIs need their vendor
install metadata for self-update, so mise no longer owns them. The global mise
config ignores old Codex CLI requests to prevent reinstallation. Orca has no
standalone installer and stays in its vendor Homebrew tap.

`harness update` runs vendor updates in parallel and aggregates failures. The
Homebrew cask updates share the package-writer lock. The global mise postinstall
hook updates installed agents, including on no-op installs. A zsh helper covers
no-op `mise up` and `mise up --local`, where mise may not run an install hook,
and suppresses the native hook to avoid duplicate updates. Setup installs Pi
after the Node inventory. T3 follows nightly explicitly; noninteractive updates
leave its running background service for manual restart.

mise owns pnpm directly, before Node, so Corepack wrappers do not shadow it.
The Xcodes GUI uses mise's GitHub backend and retains its app bundle; the
separate xcodes CLI installs Xcode. Mobile setup is enabled by default.
The explicit mobile skip does not remove tools from the common inventory.

## GitHub and shell startup

GitHub CLI owns API credentials. Bootstrap installs only pinned gh in isolated
configuration. `dotfiles-gh-real` resolves its installed binary without mise,
shims, or the routing wrapper; mise uses that helper for tokens without storing
them. API access gates broad tool acquisition; SSH readiness is separate.
Preserve existing identities, require passphrases for new SSH keys, and verify
GitHub host keys against published material.

Git identity, SSH identity and API account routing remain separate and local.
The gh wrapper supplies a selected stored token to one command; explicit token
variables remain authoritative. Shell startup uses static shims and verified
installed integrations, without provisioning or credential discovery.

## Apple tooling, consent and configuration

Use public Apple releases only. Preflight stops on offered macOS updates,
unknown update status, or apparent prereleases. Its human-readable catalog
probe fails closed; it cannot prove availability outside the active catalog.
Setup never installs OS updates or changes beta enrollment.

App privacy permissions are manual. Setup does not maintain or print app
permission lists, grant TCC consent, or edit its database. App settings and
portable backups remain managed separately from permission grants. Touch ID for
sudo remains automatic as an authentication setting. Login items are matched by app path;
missing apps and failed additions remain retryable. NearDrop quarantine stays
intact. General defaults are stamped; screenshot repair is independent so a
stamp cannot suppress destination repair. Screenshot toolbar keys are observed
macOS implementation details, not a documented API; readback is checked and
actual capture remains manual. Temporary `caffeinate` applies during setup;
the separate defaults script currently disables display sleep (an open defect).

CLIProxyAPI configuration is linked before Homebrew starts its service. It binds
to loopback; credentials stay local. Neovim is a separate submodule linked into
HOME. Its plugins are installed at editor startup, not by this planner.

## Portable state

Mackup uses explicit copy-mode backup/restore with a narrow allowlist. It must
not own repo-managed symlinks. Synology Drive is primary and iCloud is a
best-effort secondary/fallback. Raycast uses encrypted app exports instead of
its full support directory.

Codex uses an age-encrypted allowlist of portable configuration, memories and
automation definitions. Authentication, runtime, database and global app state
are excluded. Restore preserves active files and stages incoming conflicts;
replacement requires `--replace`. Shared discovery preserves provider priority
and checks hydration before selecting files. Archive path checks do not certify
that allowed executable configuration is safe.

Personal skills come from a reviewed commit and an explicitly installed,
reviewed skills CLI. Skills and generated locks remain local, outside the repo
and Codex archives.

## Diagnostics and maintenance

System Bash and `/usr/bin/ruby` support diagnostics before managed tools work.
Private per-run logs retain sanitized output and per-process events;
authentication output is omitted. INT/TERM cancels owned descendants with
bounded escalation, then releases locks. Logs are removed only after review.

The shell's daily background Git fetch only notifies. `dotfiles-update` pulls
and reapplies configuration. Agent cask upgrades run only through explicit
harness/mise commands and the mise setup hook.
Mocked tests verify contracts, not successful clean-Mac provisioning. See
[real-machine validation](SETUP-SECURITY.md#real-machine-checks-still-required).
