# Security

## Keep private state out of Git

Never commit credentials, private identities, machine-local paths, backup
payloads, or app state. This includes Raycast exports, Codex archives and
memories, Mackup contents, caches, histories, and databases.

Keep local shell settings in ignored `home/.config/local/*.zsh` files or
`~/.config/local/*.zsh`. Use Keychain-backed tools for secrets. Track only
sanitized `*.example` files. Before a commit, inspect new config files for
private values and run `git diff --cached --check`.

## What setup trusts

Bootstrap pins the mise, gh, and Homebrew installer inputs. The mise lockfile
records tool versions and available checksums. pipx dependency graphs include
hashes. Some backends record only versions. Homebrew entries have no lockfile.
The four-day release delay limits exposure to new releases. It cannot prove
that a package is safe. Explicit exclusions, required features, and requested
mise releases can bypass the delay.

Socket Firewall Free covers only wrapped commands. Bun, installers, mise
backends, casks, plugins, extensions, and personal skills run without it.
Bun remains the default runner. [Bun 1.4.4](https://bun.com/blog/bun-v1.4.4)
blocks the compromised emSign intermediate keys and removes three affected
roots. Rebuild executables that embed older Bun versions. Keep TLS verification
enabled.

The macOS Conda dependency graphs lock ca-certificates 2026.10.19 to remove the
emSign ECC Root CA G3 after the [CA security incident](https://blog.python.org/2026/10/python-3151-3149-31317/).
This is a security exception to the four-day release
delay and uses the same noarch archive as Linux. Existing tool environments
need an explicit reinstall to use the new bundle.

ImageMagick remains at 7.1.2-31 because conda-forge has not published the
[7.1.2-34 security fixes](https://github.com/ImageMagick/ImageMagick/security/advisories).
Avoid untrusted images until the fixed package is available.
Conda's SoX 14.4.2 also has unresolved audio parser vulnerabilities, including
[CVE-2026-111157](https://www.cve.org/CVERecord?id=CVE-2026-111157).
Avoid untrusted audio, or process it in an isolated account without sensitive
files or network access.
Typst 0.15.1 also has an unreleased [`typst init` path traversal fix](https://github.com/typst/typst/security/advisories/GHSA-rw6x-h3xm-cvq5).
Use only trusted local packages or Typst Universe packages, and inspect the
generated files before sharing them.

Brewfiles declare tap trust. Setup preserves quarantine, checks GitHub SSH
host keys against published values, and requires passphrases for new SSH keys.
During setup, other processes can use its temporary sudo grant. Do not run
untrusted code until setup exits. See [the grant rules](DECISIONS.md#temporary-sudo-grant).

## Check a fresh Mac by hand

On a disposable Mac with public Apple releases, check Command Line Tools,
Keychain and device login, SSH prompts, sudo in stages without a terminal,
Xcode installation, iOS downloads, cloud backup downloads, GUI imports, and
macOS permission prompts. Never use personal backups or credentials.
