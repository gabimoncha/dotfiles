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

On 2026-10-24, the mise pin moves to
[2026.10.18](https://github.com/jdx/mise/releases/tag/v2026.10.18), published
on 2026-10-23. This security exception bypasses the four-day release delay.
Its [upstream lockfile](https://github.com/jdx/mise/blob/v2026.10.18/Cargo.lock)
updates `aws-smithy-json` from 0.62.3 to 0.65.0 for
[CVE-2026-18140 / GHSA-8ffr-xgwf-xj56](https://github.com/advisories/GHSA-8ffr-xgwf-xj56),
fixed in 0.62.7 and later. It also updates `lru` from 0.16.4 to 0.18.5 for
[RUSTSEC-2026-0253](https://rustsec.org/advisories/RUSTSEC-2026-0253.html),
fixed in 0.18.2 and later. mise 2026.10.18 still bundles `zip` 8.6.0 through
`ubi` 0.12.0. It also retains `rsa` 0.9.10. The repo has no configured S3 or
ubi backend. This configuration does not remove those bundled dependencies.

On 2026-10-24, the uv pin moves to
[0.13.5](https://github.com/astral-sh/uv/releases/tag/0.13.5), published
on 2026-10-22. This security exception bypasses the four-day release delay.
It is the smallest patched uv release for
[CVE-2026-111943 / RUSTSEC-2026-0382](https://rustsec.org/advisories/RUSTSEC-2026-0382.html).
Its [upstream lockfile](https://github.com/astral-sh/uv/blob/0.13.5/Cargo.lock)
updates `rustls-webpki` from 0.103.14 to 0.103.16. uv 0.13.4 already removed
the emSign root. uv 0.13.5 adds explicit rejection of compromised intermediate
public keys. This update does not establish that all transitive dependencies
are free of vulnerabilities.

On 2026-10-24, the Ruby pin moves to
[3.4.12](https://www.ruby-lang.org/en/news/2026/10/23/ruby-3-4-12-released/),
published on 2026-10-23. This security exception bypasses the four-day release
delay. It is the first 3.4 release with all four Regexp memory error fixes in
[the Ruby advisory](https://www.ruby-lang.org/en/news/2026/10/23/regexp-fixes-for-gitlab-cves/).
Ruby directs scanners to use GitLab-assigned CVE-2026-89078, CVE-2026-93577,
CVE-2026-97229, and CVE-2026-110264 for these underlying bugs.
GitLab's CVSS scores describe GitLab, not Ruby alone. This repo has no GitLab
server. The trigger requires an application to compile attacker-controlled
patterns. No such call is shown in this repo. The runtime patch remains
required. Both locked platforms compile the same verified source archive.
Compilation stays enabled because precompiled Ruby 3.4.11 bundled OpenSSL
3.5.5. This does not establish what precompiled 3.4.12 binaries contain.

The Ruby 3.4.12 source still bundles json 2.9.1, which remains affected by
[CVE-2026-54696](https://github.com/ruby/json/security/advisories/GHSA-x2f5-4prf-w687).
The runtime bump does not fix that separate JSON generator memory error.

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
