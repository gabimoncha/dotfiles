# Setup security and manual validation

Follow the [setup procedure](README.md#fresh-mac) for the permission/restart
checkpoint. Setup cannot grant or reliably query App Management consent.
No broad permission grant or destructive probe is required merely to install
packages. Current implementation defects are listed under
[known limits](README.md#known-limits).

Bootstrap mise, gh, and Homebrew installer inputs are pinned. Healthy mise
installations are reused. General inventory entries using `latest` are not a
lockfile; mise's four-day release-age setting and explicit exceptions reduce
exposure to new releases, not to malicious older releases.

## Execution policy

The interactive SFW aliases intercept only the commands they wrap. The Bun/Bunx
branch of `npx`/`bx`, direct Bun calls, noninteractive Bash installers, mise
backends, Homebrew casks, shell plugins, editor extensions, and personal skills
are separate execution paths. None gains SFW coverage merely because SFW is
installed. SFW wrapper limitations include private/custom registries, offline
use, and telemetry controls; do not treat it as a private registry policy engine.
Inspect package source, publisher, install scripts and permissions
before explicitly running unfamiliar code. Bootstrap-critical acquisition is
narrow and bounded; the complete developer inventory remains a deliberate
large trust surface.

Tool inventory changes are separate from setup cleanup. Review optional tools
before adding or removing them. Personal skills require a reviewed installed
CLI and a reviewed source commit; see [manual completion](README.md#manual-completion).

NearDrop quarantine is left intact, including on an existing application.
Homebrew tap trust remains explicit in the Brewfiles; no global bypass is used.
GitHub SSH keys are checked against published host key material. New private
keys require a nonempty passphrase; existing keys are preserved. An already
configured SSH agent can be used without exporting a private key.

## Optional security tools

Distribution and capabilities checked against vendor and Homebrew documentation
on 2026-09-13. These are evaluations, not additions to the managed inventory.
Follow `mas → mise → Homebrew` again if adding one later: these desktop security
utilities are not language runtimes, and their privileged vendor components
need a supported desktop distribution rather than an assumed mise backend.

| Tool | Available distribution | Manual setup and limitation |
| --- | --- | --- |
| LuLu | [vendor](https://objective-see.org/products/lulu.html), [Homebrew cask](https://formulae.brew.sh/cask/lulu) | Approve the system extension and network filter, then review rules. It controls outgoing connections; an allowed app can still send data. |
| BlockBlock | [vendor](https://objective-see.org/products/blockblock.html), [Homebrew cask](https://formulae.brew.sh/cask/blockblock) | Complete privileged installation and requested privacy approvals; review persistence alerts. It is not a complete malware detector. |
| 1Password SSH agent | [agent security model](https://developer.1password.com/docs/ssh/agent/security/), [desktop cask](https://formulae.brew.sh/cask/1password) | Optional paid service, not selected by setup. Enable the agent and choose narrow authorization, preferably per request where practical. Broad session approval also authorizes descendants. |
| KnockKnock | [vendor tool list](https://objective-see.org/tools.html), [cask](https://formulae.brew.sh/cask/knockknock) | Optional persistence inspection; interpret findings and grant only permissions needed for the inspection. A clean scan does not prove a clean machine. |
| ReiKey | [vendor tool list](https://objective-see.org/tools.html), [cask](https://formulae.brew.sh/cask/reikey) | Optional keyboard event-tap diagnostic. Investigate legitimate accessibility tools as well as unknown taps; it does not cover every form of credential theft. |

Installed software is not evidence that its protection is configured or active.
Verify vendor signatures, compatibility, permissions and effective behavior on a
real disposable Mac before making any tool part of the default bootstrap.

## Disposable interview and untrusted-code environment

Use a separate disposable VM or workstation with a fresh local account and only
the tools needed for the exercise. Do not mount host HOME or personal cloud
folders, forward an SSH agent, copy tokens, sign into personal browsers, or
reuse a credential-bearing developer environment. Use narrowly scoped,
short-lived test credentials only if the exercise requires access; destroy the
environment and revoke those credentials afterward. A container sharing host
paths or sockets is not this isolation boundary.

macOS protects selected locations and services through privacy permissions;
it does not make every file in HOME unreadable to software running as you.
Avoid granting broad Full Disk Access, Accessibility, Input Monitoring or
Automation access to interview tooling. FileVault protects data at rest on a
locked/offline disk, not secrets already accessible during your logged-in
session. After suspected exposure, use a trusted device to revoke sessions and
rotate API tokens, SSH keys and affected passwords; rebuilding alone does not
invalidate stolen credentials.

Before restoring after a compromise, inspect executable configuration, shell
hooks, editor extensions, skill instructions and scheduled automations. The
Codex archive allowlist/path validation prevents unexpected archive paths; it
does not certify the safety of allowed file content. Setup asks before eligible
restores and preserves existing Codex portable state by default.

## Real-machine checks still required

Fixture tests do not establish a successful fresh-Mac installation. On a
disposable public-release Mac, verify Command Line Tools handoff, simultaneous
foundation provisioning, Keychain/device login, protected SSH/agent prompts,
Homebrew sudo behavior, Xcode/Apple ID and iOS downloads, App Store sign-in,
cloud backup hydration, GUI imports, and macOS permission prompts. Interrupt a
representative long install in a terminal and confirm its own installer leaves
a recoverable state. Never use personal backups or credentials for this test.
