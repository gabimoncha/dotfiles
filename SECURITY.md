# Security

This repo must stay safe to clone onto a fresh Mac without exposing private state.

## Keep private state out of Git

Do not commit:

- API keys, tokens, passwords, cookies, or auth headers
- Private email addresses beyond public noreply-style Git config
- Machine-local absolute paths outside this repo model
- Raycast `.rayconfig` exports or their passphrases
- Decrypted Codex state archives, raw Codex memories, or Codex memory exports
- Raw Codex global app state, project/workspace state, connection state, or
  scheduled-task memory
- Mackup backup contents
- App caches, histories, databases, or session state

Local-only shell state belongs under:

```text
~/.config/local/*.zsh
home/.config/local/*.zsh
```

The tracked shell config sources those files if present. Keep secrets there or
in Keychain-backed tooling. Repo-local examples may be tracked as `*.example`;
real `*.zsh` files must stay ignored.

Before you commit, run `git diff --cached --check` and scan new config files
for private values.

## What setup trusts

Bootstrap pins the mise, gh, and Homebrew installer inputs. The mise
inventory requests `latest`, but `home/.config/mise/mise.lock` records the exact
version of each mise tool. For most tools it also records the download URL and
checksum. pipx tools record a uv dependency graph with hashes under
`home/.config/mise/locks/`. npm, gem, and Rust tools record only a version,
and some aqua and vfox tools have no upstream checksum. Homebrew `latest`
entries have no lockfile. mise's four-day `minimum_release_age` reduces
exposure to new releases, not to malicious older releases. Tools in
`minimum_release_age_excludes` skip that delay. The mise pin in
`bin/lib/mise-pin.sh` can also be newer than four days when a needed feature
requires it; that file names the feature. Review a
tool before you add it to an inventory.

The interactive SFW aliases cover only the commands they wrap. Direct Bun
calls, the Bun branch of `npx`/`bx`, Bash installers, mise backends, Homebrew
casks, shell plugins, editor extensions, and personal skills run without SFW.

Homebrew tap trust is declared per tap in the Brewfiles. NearDrop quarantine
stays intact. Setup checks GitHub SSH host keys against published values, and
new SSH keys need a passphrase.

During each setup phase, a temporary sudoers file shares one `sudo` timestamp
across your processes. Package install scripts and agent shells can then run
`sudo` without a prompt until setup exits or 30 idle minutes pass. Do not run
untrusted code while setup runs. See
[the decision](DECISIONS.md#temporary-sudo-grant).

## Check a fresh Mac by hand

No script proves a fresh-Mac install. On a disposable public-release Mac,
check the Command Line Tools handoff, Keychain and device login, SSH prompts,
the shared `sudo` timestamp in stages without a terminal, `sudo mas get` for
Xcode, iOS downloads, cloud backup hydration, GUI imports, and macOS permission
prompts. Never use personal backups or credentials for this check.
