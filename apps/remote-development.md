# Local SSH access for remote development

SSH identities and host settings stay local, not managed or linked by dotfiles.
On a main Mac, Mackup backs up `~/.ssh/config` to your private backup storage.
`bin/configure-ssh-host` is an explicit opt-in helper, never run by setup. Use it
when an existing private key needs to live in your actual user home rather than
an agent/runtime home. It does not trust `$HOME`: `--home` is mandatory.

```bash
./bin/configure-ssh-host --dry-run \
  --home '/absolute/path/to/actual-home' \
  --source-key '/absolute/path/to/existing-private-key' \
  --key-name 'KEY_NAME' --alias 'HOST_ALIAS' \
  --hostname 'HOSTNAME' --user 'REMOTE_USER' --port 'PORT'
```

Replace every placeholder; omit `--port` for port 22. Review the preview, then
repeat without `--dry-run`. Run as the user who owns the home and source key,
not with sudo. The home must already exist. The helper copies only the private
key; it does not generate keys, register public keys remotely, modify known
hosts, contact the host, or delete the source.

- Existing config bytes are preserved and a new `Host` block is appended.
  A unique `~/.ssh/config.backup-*` copy is retained before changing a config.
- The SSH directory gets mode 700; destination key, config and backup get 600.
- An identical destination key can be reused; a different key is rejected.
  Symlinked or multiply linked files and a symlinked SSH directory are refused.
- An overlapping `Host` pattern (including wildcards), `Match`, or global
  connection settings is refused. A repeated invocation with the same alias
  therefore refuses without appending.
- `Include` is refused unless you explicitly pass `--reviewed-includes` after
  reviewing the included files. This trusts their contents: do not use it with
  untrusted files or included `Match` rules (`Match exec` can execute commands
  even during `ssh -G`). Direct `Match` rules remain refused.
- Before copying a key or replacing config, the helper evaluates a private
  temporary candidate with `/usr/bin/ssh -G -F CANDIDATE HOST_ALIAS`. It requires
  the requested hostname, user, port, `IdentitiesOnly yes`, and exactly the
  requested identity file. Conflicting included defaults are rejected.
- Dry run performs the same effective-settings check and removes its temporary
  candidate; it changes no destination files. Private-key contents are never
  printed. Header validation is not proof of a usable key.
- Do not edit the SSH config concurrently. A failed run can leave a safely
  copied key and backup; the source remains available. After an interrupted run,
  review any `.configure-ssh-host.lock` directory before removing the stale lock.

When using `--reviewed-includes`, inspect `ssh -G HOST_ALIAS` from an ordinary
user terminal **before and after** running the helper. Included defaults use
first-value-wins semantics. Review proxy/routing settings too: the candidate
check covers only the five settings above and `-F` skips system-wide config.
Relative and tilde Includes resolve using SSH's actual user home, not `--home`;
run as the intended user and do not change included files during migration.

Verify the connection from an ordinary user terminal so SSH uses the actual home:

```bash
ssh HOST_ALIAS
```

Check the remote host fingerprint through a trusted channel when prompted.
Only after a successful connection with the migrated identity should you decide
whether to remove the original source key. Keep all identities, backups and
machine-specific host details outside this repository. To undo the config edit,
restore the indicated backup (or remove only the added block if no config existed);
review subsequent edits first. Remove the copied key only if nothing else uses it.

## SSH from Ghostty

The Ghostty config enables `ssh-env` and `ssh-terminfo`. In Ghostty 1.4 and
later, shell integration makes `ssh HOST_ALIAS` use `ghostty +ssh`. The wrapper
installs Ghostty's terminfo on the remote host and caches successful installs.
If installation fails, for example because the remote host has no `tic`, the
connection continues with `TERM=xterm-256color`.

The wrapper also requests forwarding of `COLORTERM`, `TERM_PROGRAM`, and
`TERM_PROGRAM_VERSION`. The remote SSH server must allow these variables with
`AcceptEnv` to receive them. `TERM` does not need that setting.

After a config change, reload Ghostty's config and open a new terminal.
Use `command ssh HOST_ALIAS` to bypass the wrapper for one connection.
See [Ghostty's SSH guide](https://ghostty.org/docs/features/ssh) for details.

## NAS T3 container

The private fleet repo holds the Compose file of the `nasbox` project and
its deploy steps (`hosts/synology/`). The compose file does not install T3 or
the agent CLIs; `./bin/setup` installs them in the persistent home (see
"Dotfiles on the box").

### Daemons

The container has no systemd. Two mise daemons in `mise.container.toml` run
T3 and the tokenburnmarket sync daemon as `box`, under the pitchfork
supervisor. The compose command starts them when the container starts. It
tries again each minute until a first start succeeds, for example while setup
still installs mise. Later, within a minute after pitchfork dies or another
pitchfork replaces it, it starts every daemon again. When the container stops, it runs `pitchfork supervisor stop` before it
stops sshd. The supervisor refuses new starts, waits for a start in progress,
and stops every daemon with its own stop timeout, so T3 can stop its server.
Then `bin/t3-dev-supervise --stop-orphans` stops a T3 launcher whose script
died, which pitchfork cannot reach. `stop_grace_period: 130s` covers the t3
daemon's 95 seconds.

To move the NAS to these daemons, first update the checkout in the box:
`git -C ~/code/personal/dotfiles pull`, then check that
`~/code/personal/dotfiles/bin/container-daemons` exists. The new command
starts nothing without it. Then replace the whole `command` block in the
compose file on the NAS with the one in the example, and add
`stop_grace_period: 130s`. The old command started two loops from
`~/.local/bin`, and a rebuild with only the new grace period keeps them. Then
rebuild the project, and keep the volumes.

Run every daemons command through `./bin/container-daemons`, not
`./bin/repo-mise daemons`. The supervisor keeps the environment of the command
that starts it, and `repo-mise` hides the global tools. Run it in the main
checkout. The daemons use the fixed namespace `nasbox`, so a start from a
second checkout or a worktree stops with "external configuration conflicts
with namespace 'nasbox'".

```bash
./bin/container-daemons status
./bin/container-daemons logs t3
./bin/container-daemons restart tokenburnmarket
```

Each daemon runs a script from this checkout: `bin/t3-dev-supervise` and
`bin/tokenburnmarket-supervise`. The script restarts its service after every
exit, as the systemd units of T3 and tokenburnmarket do. pitchfork keeps one
copy of each script and keeps their output. At its start, a script stops an
earlier copy of itself and a service that an earlier run left, for example
after the out-of-memory killer ended a script. The tokenburnmarket script also
removes a stale `daemon.lock`, whose PID a new process can have after an
unclean stop. `MISE_AUTO_INSTALL=0` keeps a failed install of another tool
from stopping the daemons. `running` in `status` means that
the script runs, not that T3 answers. Check T3 in the app, or read
`logs t3` for "no complete runtime" and launcher errors. The setup step
`tokenburnmarket` signs in, and restarts its daemon when `mise up` has moved
node or the CLI. The tokenburnmarket script also checks once an hour, so a
`mise up` outside setup reaches the daemon within an hour. mise owns the
tokenburnmarket updates, so the script sets `TBM_NO_UPDATE_CHECK=1`. The CLI
cannot update a mise install itself, and its update notice names an npm
install that mise does not track.

A restart keeps the container and its system packages. A build makes a new
container from the image, which removes what apt installed. At each start, the
entrypoint runs `bin/container-system-packages` in the background. In a new
container, it installs the setup prerequisites and the packages in
`[bootstrap.packages]`, and sets the zsh login shell. A marker in
`/var/lib/dotfiles/` makes a restart skip it, and a failed run tries again at
the next start. It logs to `~/.local/state/dotfiles/container-system-packages.log`.
Add a system package to `mise.container.toml`, not with a manual `apt-get`.

### T3 install and updates

Install T3 with the official script, not the `t3` npm package:

```bash
curl -fsSL https://t3.codes/install.sh | T3CODE_CHANNEL=nightly sh
```

The script writes `~/.local/bin/t3` as a two-line shell file that runs
`~/.t3/runtime/versions/VERSION/t3`. Installers before
0.1.11-nightly.20261118.4877 wrote a link there instead. Setup accepts both.
The npm package runs only the runtime that matches its own version, so it
ignores updates.
Do not run `npm uninstall -g t3` after a change to the script install. npm
also deletes `~/.local/bin/t3`. Rerun the install script if that happens.

The container has no systemd, so `t3 service install` cannot run. The
supervisor does what its unit does: it runs `t3 __service-launcher`, and the
launcher starts `t3 serve`. The server then tells the T3 app that it can
update itself, so update the box from the app. The launcher backs up the
database first and returns to the old version when the new one fails to start.
The launcher runs the version in `~/.t3/runtime/service-state.json`. That
server must speak the protocol of the launcher. Otherwise the server stops at
once with "The service launcher supplied invalid startup context". Before each
start of the launcher, the supervisor does the work of `t3 service install`.
When the file is missing, or names a version older than the runtime that
`~/.local/bin/t3` runs, the supervisor writes that runtime and the
protocol in `launcher_protocol` to the file. It keeps the old file as
`service-state.json.bak`. It keeps a newer version that the app installed.
When the launcher exits, the supervisor starts it again after 5 seconds.
`./bin/container-daemons logs t3` shows the output.

When the app reports that the launcher speaks an older protocol, install the
CLI version from the error message with the install script. Then stop the
launcher with `pkill -TERM -f "t3 __service-launcher"`, and the supervisor
starts the new one. If the error names a protocol higher than
`launcher_protocol` in `bin/t3-dev-supervise`, change that number first. When
SSH and the T3 terminal do not work, run the commands as root from a DSM Task
Scheduler script with `docker exec -u box nasbox`.

After a change to `bin/t3-dev-supervise` or to the daemons in
`mise.container.toml`, pull the checkout and run
`./bin/container-daemons restart t3`.

The ports, the SSH alias of a main Mac, and the key setup are in fleet.
`bin/configure-ssh-host` refuses a config with `Match` blocks, such as the
fleet alias for `nasbox`, so run it before you add that block, or remove the
block first. Mackup backs up `~/.ssh/config` on a main Mac (see
[MACKUP.md](../MACKUP.md)). Memory and total RAM+swap
are both capped at 6 GiB. This is a ceiling, not reserved RAM; on an 8 GiB NAS,
full container usage leaves roughly 2 GiB for DSM and all other workloads.
The container has no Docker socket or personal shares.

For memory changes, update both Compose limits and rebuild the existing project
without deleting volumes. Docker also supports live limit updates, but these do
not update the Compose source. Recreation interrupts processes and connections;
Claude and Codex credentials in the persistent home volume survive it.

T3 Connect is the main route. The server starts a `cloudflared` tunnel to
T3's managed relay, and the log reports "T3 Connect is reachable from other
devices". The direct routes are fallbacks: `http://TAILSCALE_IP:3773` on the
tailnet and `http://LAN_IP:3773` on the LAN. Keep both in the T3 desktop
environment. If pairing is requested, use `t3 pair --help` on the server to
create a fresh one-time link. Pairing links are credentials: do not store them
in Git, logs, screenshots, or chat. Plain HTTP relies on Tailscale encryption
for remote transport and is not encrypted on a LAN-only route.

After deployment, verify LAN SSH, the 6 GiB cgroup limits, the T3 Connect log
line, direct T3 discovery, and remote access from a device on the same tailnet. Successful LAN discovery
alone does not prove Tailscale routing, authentication, or a working agent task.

The account `box`, its volumes, and its passwordless `sudo` come from the
Compose file. fleet's `hosts/synology/README.md` covers them.

### Dotfiles on the box

The checkout is `~/code/personal/dotfiles`, also a T3 project on the box. Run the
normal setup there; it detects Linux and runs every step in one run:

```bash
cd ~/code/personal/dotfiles
./bin/setup --dry-run
DOTFILES_SKIP_GITHUB_AUTH=1 ./bin/setup   # until you log in to GitHub
```

Setup installs Ruby, Git, and curl (`bin/linux-prerequisites`), zsh,
build-essential, and unzip (`mise.linux.toml`), makes zsh the login shell,
installs the shared mise tools, and installs the tools in
`apps/standalone.tsv`: mise, Codex, Claude Code, Cursor Agent, OpenCode, Pi,
and T3. It links the shared dotfiles and skips the Mac-only ones. The agent
rules of the box come from its fleet host folder.

The apt packages and the login shell live in the container layer. After a
project rebuild or a container recreate, SSH works with bash again. Rerun
`./bin/setup` from the checkout; it reinstalls the packages and skips the
rest. The home volume keeps mise, the tools, the agent CLIs, and their logins.

Log in to GitHub on the box with `./bin/auth-setup`. It runs the GitHub CLI
login, and Git then uses that token over HTTPS through the credential helper in
`configs/git/gitconfig`. The box needs no SSH key. Until the login, mise downloads
tools without a GitHub token.

The Codex CLI sandbox cannot run here: the kernel has no user namespaces and
the container has no capabilities, so even a setuid `bwrap` fails. The
container is the boundary, so the `nasbox` folder in fleet sets
`sandbox_mode = "danger-full-access"` in `~/.codex/config.toml`.

`harness update` skips T3, so a `mise install` never restarts the server. An
update from the app restarts it, and running agent tasks stop.

## NAS agent proxy

CLIProxyAPI runs as its own Container Manager project on the NAS. Its
Compose file, Tailscale Serve, and account sign-in steps are in fleet
(`hosts/synology/README.md`). Unprefixed requests can use any eligible
account; priority alone does not prevent fallback.

Configure only Codex and Claude Code after the proxy is reachable:

On Macs, use the private Tailscale HTTPS URL. In `nasbox`, use
`http://cliproxyapi:8317` through the shared Docker network.

| Client      | Private settings on each machine                                                                                                                                                                                                 |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Codex in T3 | Set `model_providers.cliproxyapi.base_url` to the URL plus `/v1` in `~/.codex/config.toml`. Supply the proxy client key as `CLIPROXYAPI_API_KEY` in the T3 process environment. The shared T3 launch arguments select the proxy. |
| Claude Code | In `~/.claude/settings.json`, set `env.ANTHROPIC_BASE_URL` to the URL and `env.ANTHROPIC_AUTH_TOKEN` to the client key. Do not set `env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`.                                             |

Claude Code shows only its own models. With gateway model discovery, Claude
Code adds every model of the proxy to its model list, and T3 shows each one
in the Claude picker. The proxy gives each non-Claude model to Claude clients
under a changed `claude-…` ID. A provider with a model prefix lists each model
two times: with the prefix and without it.

The tracked Codex provider uses native `env_key` authentication. Remove an old
`model_providers.cliproxyapi.auth` block before using it. For GUI and T3 starts,
the parent process must receive `CLIPROXYAPI_API_KEY`; a terminal export alone
does not configure a running app. On macOS, a private
`~/.config/local/cliproxyapi.zsh` supplies the key to interactive shells. A private
`~/Library/LaunchAgents/local.cliproxyapi.environment.plist` loads that file and
runs `launchctl setenv` at login for apps opened from the Dock. Reopen an app
that was already running when the environment changed.
Remove conflicting Claude auth helpers and cloud-provider overrides. Restart
clients after configuration.
`./bin/save-settings` excludes the private URLs and tokens.
Shared settings still use `./bin/link-dotfiles` and `./bin/save-settings`.

T3's shared settings target `~/.t3/userdata/settings.json` on macOS and Linux.
They preserve `-c thread_unload_delay_secs=60` and add
`-c 'model_provider="cliproxyapi"'`. The global Codex provider is `openai` so
the desktop app can use ChatGPT sign-in. To migrate an existing host, first
apply the T3 settings, then the Codex settings:

```bash
./bin/link-dotfiles --dry-run ~/.t3/userdata/settings.json ~/.codex/config.toml
./bin/link-dotfiles ~/.t3/userdata/settings.json
./bin/link-dotfiles ~/.codex/config.toml
```

Apply while no one edits T3 settings. Start a fresh T3 provider process and
reopen the desktop app after the migration. For a terminal Codex session that
needs the proxy, use `codex -c 'model_provider="cliproxyapi"'`.

Verify both agents from outside the LAN, including tool calls, account selection,
and token refresh. After that, remove the old Mac proxy with
`brew services stop cliproxyapi` and `brew uninstall --formula cliproxyapi`.
Keep its OAuth files until the migration is complete.

### Proxy routing

The server example enables session affinity for one hour. New sessions use
round-robin selection. A session keeps its account while that account remains
available, and child sessions inherit the parent's account. Failover remains
enabled. The affinity duration does not set Claude's prompt-cache duration.
The shared Codex provider enables Responses WebSockets. Start a fresh T3
provider process after applying the Codex settings.

For an existing hub, merge the `routing` and `observability` sections from
the fleet file `hosts/synology/cliproxyapi/config.yaml.example` into its
private configuration. Preserve
its keys, accounts, and other settings. CLIProxyAPI hot-reloads configuration.
Updating the example alone does not change the deployed NAS configuration.

Full request logging and debug logging stay off. Docker retains application
stdout with its existing rotation limits. Error log files can still contain
request content. Keep those files private and inspect them before sharing.

## Devstation Mac

The Mac mini uses the `devstation` role. It runs the T3 server with no desktop
app, and you use it through SSH. `./bin/setup --continue` runs two steps for
this role only, on a Mac: `t3_service` and `remote_access`. Both steps are
untested on a real Mac mini.

### T3 server

Setup installs `t3` with the vendor script, as on the NAS container, and
`bin/setup-t3-service` runs `t3 service install`. Then run `t3 up` and choose
how your other devices reach the server. The T3 app on another machine updates
the server.

The service needs the proxy key in its environment. Codex in T3 reads
`CLIPROXYAPI_API_KEY` from the T3 process, and a terminal export does not
reach a login service. Use the private files of the
[NAS agent proxy](#nas-agent-proxy) section: `~/.config/local/cliproxyapi.zsh`
and the login job that runs `launchctl setenv`. At login, the T3 service can
start before that job, and then it has no key. The restart test on the Mac
mini showed this. So the login job on the Mac mini runs a private script,
`~/.config/local/cliproxyapi-environment.sh`. After `launchctl setenv`, the
script reads the process of `com.t3tools.t3code.service`. If that process has
no `CLIPROXYAPI_API_KEY`, the script runs `launchctl kickstart -k` on the
service one time. A later run of the job finds the key and does not restart
the service. Set the
proxy URL to the NAS's Tailscale HTTPS URL, as on the other Macs, so the Mac
mini needs Tailscale signed in before the agents work.

### Remote access

`bin/configure-remote-access` turns on Remote Login, turns off system sleep,
makes the Mac restart after a power failure, and turns on automatic login. It
changes only the `devstation` role. `--status` reports each setting and
`--dry-run` previews the changes.

The T3 server, tokenburnmarket, and the process log are login jobs. They start
only in a user session, so the Mac must log in by itself after a restart.
macOS allows automatic login only with FileVault off. With both choices, a
person at the Mac gets your session without a password. The script stops when
FileVault is on and never turns it off. To continue, turn off FileVault in
System Settings, wait for decryption to finish, and rerun the script. It then
asks for the account password.

The script's header comment lists the commands that undo each change.

Automatic login shows the desktop with no password. The login job
`lock-screen` in `mise.devstation.toml` runs `bin/lock-screen`, which locks the
screen in the first minutes after a start. The account stays logged in behind
the lock, so SSH, the T3 server, and the other login jobs continue to work.
Tools that read or click the real screen, such as `agent-desktop`, see the lock
screen until you unlock it. `./bin/lock-screen --now` locks at any time.

### What the Mac mini leaves out

The root `Brewfile` and the shared lists in `apps/` are the complete app
inventory of the Mac mini. It has no dictation apps, no Synology Drive, no
Mackup, and no T3 Code desktop app. Setup restores only the Raycast export,
from iCloud Drive or from a path that you pass to `./bin/file-restore raycast`.
`./bin/file-backup raycast` saves a new export to iCloud Drive.
