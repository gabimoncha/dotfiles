# Local SSH access for remote development

SSH identities and host settings stay local, not managed or linked by dotfiles.
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

## NAS T3 container

`local/nasbox.compose.yaml.example` is a sanitized deployment example.
Keep the machine-specific copy under ignored `local/nasbox/` and
upload its `compose.yaml` to the Container Manager project `nasbox` in
`/volume1/docker/nasbox`.
Replace the documentation-only LAN address and public-key placeholder first.
Do not commit actual host addresses, identities, keys, or pairing links.

The example preserves the existing named home and SSH host-key volumes and
workspace bind mount. The compose file does not install T3 or the agent CLIs;
`./bin/setup` installs them in the persistent home (see "Dotfiles on the box").
Install `bin/t3-dev-supervise` there as `~/.local/bin/t3-supervise` (mode 0700). The
container starts it as that user. Changes take effect on a container restart;
port-mapping changes require a project rebuild. Do not delete persistent volumes.

The tokenburnmarket sync daemon also needs a supervisor here. The setup step
`tokenburnmarket` signs in, installs `bin/tokenburnmarket-supervise` as
`~/.local/bin/tokenburnmarket-supervise`, and starts it. The example compose
file starts it after a container restart. Copy that line into the compose file
on the NAS. The daemon logs to `~/.local/state/tokenburnmarket/daemon.log`.

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

The script links `~/.local/bin/t3` to `~/.t3/runtime/versions/VERSION/t3`.
The npm package runs only the runtime that matches its own version, so it
ignores updates.
Do not run `npm uninstall -g t3` after a change to the script install. npm
also deletes `~/.local/bin/t3`. Rerun the install script if that happens.

The container has no systemd, so `t3 service install` cannot run. The
supervisor does what its unit does: it runs `t3 __service-launcher`, and the
launcher starts `t3 serve`. The server then tells the T3 app that it can
update itself, so update the box from the app. The launcher backs up the
database first and returns to the old version when the new one fails to start.
The launcher runs the version in `~/.t3/runtime/service-state.json`. On the
first start, the supervisor writes that file with the runtime that
`~/.local/bin/t3` links to. `t3 update` moves only that link and does not
change the running server. When the launcher exits, the supervisor starts it
again after 5 seconds. The current log is `~/.local/state/t3/server.log`, and
the log of the previous start is `server.log.1`.

SSH publishes port 2222 on the specified LAN address only. T3 publishes port
3773 on the NAS interfaces for LAN and Tailscale access. Keep router
forwarding/UPnP exposure disabled. Port 3773 is not a public HTTPS endpoint.
Tailscale ACLs and DSM firewall rules still apply. Memory and total RAM+swap
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

### Container account

The non-root account is `box` (UID/GID 1000), with home `/home/box`.
Startup renames the base image's `node` account without changing its numeric
identity. The same `dev-home` volume mounts at `/home/box`; `/home/node` is a
compatibility symlink for existing absolute launcher paths and saved settings.
The image's original home directory is retained as `/home/node.image-default`
in the disposable container layer. Do not remove the compatibility symlink
without auditing existing launchers and settings.

Use `User box` in the local SSH alias. Until that local setting is updated,
`ssh box@HOST_ALIAS` overrides the old username. T3's direct routes do not use
an SSH username; any manually configured SSH route also needs the new user.
The project, the container, the hostname, and the network are `nasbox`. The
volumes keep the names of the first project: `t3-dev_dev-home` and
`t3-dev_ssh-host-keys`. Docker cannot rename a volume, so the Compose file
names them with `external: true`. Compose then never makes or deletes them,
even when the project is deleted. The image is `node:latest` with `pull_policy: always`, so each build gets
the newest Node.js image on the current Debian release. The box does not run
the image's Node. This account rename does not change installed runtimes or
privileges.

### Passwordless sudo inside the container

Compose startup installs `sudo` and creates `/etc/sudoers.d/90-t3-box`, owned
by root with mode 0440, containing `box ALL=(ALL:ALL) NOPASSWD: ALL`.
It validates the rule and complete sudo configuration with `visudo`, then tests
`sudo -n id -u` as `box` before starting services. The container log prints
`box passwordless sudo verified` only after that test succeeds.

This intentionally lets every process running as `box`, including coding
agents, become root inside the container. It does not add host mounts, a Docker
socket, privileged-container mode, or DSM SSH. It does weaken isolation within
the container and permits changes to mounted workspace files as root. System
packages installed through sudo live in the disposable container layer unless
also included in startup or a custom image.

To revoke this grant durably, remove the sudoers creation/test block from the
Compose source and recreate the existing project without deleting its volumes.
Removing only the live sudoers file is temporary: startup creates it again.

### Dotfiles on the box

The checkout is `~/development/dotfiles`, also a T3 project on the box. Run the
normal setup there; it detects Linux and runs every step in one run:

```bash
cd ~/development/dotfiles
./bin/setup --dry-run
DOTFILES_SKIP_GITHUB_AUTH=1 ./bin/setup   # until you log in to GitHub
```

Setup installs Ruby, Git, and curl (`bin/linux-prerequisites`), zsh,
build-essential, and unzip (`mise.linux.toml`), makes zsh the login shell,
installs the shared mise tools, and installs the tools in
`apps/standalone.tsv`: mise, Codex, Claude Code, Cursor Agent, OpenCode, Pi,
and T3. It links the shared dotfiles and skips the Mac-only ones. Agents read
the box rules from `configs/agents/container.md`; see the Linux section of
the README.

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
container is the boundary, so `bin/link-dotfiles` sets
`sandbox_mode = "danger-full-access"` in `~/.codex/config.toml` from
`configs/codex/container.toml`.

`harness update` skips T3, so a `mise install` never restarts the server. An
update from the app restarts it, and running agent tasks stop.

## NAS agent proxy

Deploy the [official image](https://help.router-for.me/docker/docker-compose.html)
as a separate Container Manager project. Docker installs and restarts it.
The NAS keeps its configuration and OAuth files outside `nasbox`.

1. Copy `local/cliproxyapi.compose.yaml.example` to ignored
   `local/cliproxyapi/docker-compose.yml`. Copy `local/cliproxyapi.config.yaml.example`
   to `local/cliproxyapi/config/config.yaml`.
2. Replace both key placeholders with different keys from your secret manager.
   Keep the configuration mode 0600 and the config and auth folders mode 0700.
3. Upload this private folder to the NAS and create its Container Manager
   project. It joins the `nasbox` network, so create the `nasbox` project first.
   Keep `config/` and `auths/` on persistent NAS storage. Use the logs and
   terminal in Container Manager to debug it.
4. The image is `latest` with `pull_policy: always`. Build the project again
   to update it. The build stops the proxy for about a minute, and the clients
   that use it fail during that time. No changes to the `nasbox` project are
   needed.

The API port binds to NAS loopback. Use the NAS's existing
[Tailscale Serve](https://tailscale.com/kb/1312/serve) for HTTPS access from the
tailnet. On the NAS host, inspect `tailscale serve status` first. If port 8443
is unused, configure `tailscale serve --bg --https=8443 http://127.0.0.1:8317`.
These are host commands, not commands inside `nasbox`. Keep the returned URL
private. Verify tailnet access before activating clients; NAS Serve setup has
not been applied by dotfiles. Do not enable public Funnel access.
The first Serve command can print an approval URL and wait. Open that URL to
enable Serve before expecting the command or its Task Scheduler email to finish.

Open `/management.html` at that URL and enter the management key. Sign in to
the OpenAI and Anthropic accounts in the
[web UI](https://help.router-for.me/management/webui.html), using its callback
URL submission for remote logins. Only the API port needs publishing.
Use credential prefixes such as `work` and `personal` and select the matching
model name in each agent to choose an account group. Unprefixed requests can
use any eligible account; priority alone does not prevent fallback.

Configure only Codex and Claude Code after the proxy is reachable:

On Macs, use the private Tailscale HTTPS URL. In `nasbox`, use
`http://cliproxyapi:8317` through the shared Docker network.

| Client | Private settings on each machine |
| --- | --- |
| Codex in T3 | Set `model_providers.cliproxyapi.base_url` to the URL plus `/v1` in `~/.codex/config.toml`. Supply the proxy client key as `CLIPROXYAPI_API_KEY` in the T3 process environment. The shared T3 launch arguments select the proxy. |
| Claude Code | In `~/.claude/settings.json`, set `env.ANTHROPIC_BASE_URL` to the URL, `env.ANTHROPIC_AUTH_TOKEN` to the client key, and `env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY` to `"1"`. |

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

## Future GCP VM

The VM does not exist yet. `vm` (`mise.vm.toml`) is a reserved, deferred profile.
VM creation, guest setup, cloud control tasks, and hardening belong to a later
session. Do not copy the NAS container's sandbox or sudo exceptions into a VM.

Start that session with the hardening requirements. Choose the project, zone,
machine size, disk, IAM permissions, guest access, updates, and backup policy.
The earlier proposal was IAP SSH with OS Login, persistent disks, and an
ephemeral external IP for outbound access. Revisit those choices during the
hardening review before provisioning.

Then add `vm:status`, `vm:start`, `vm:stop`, `vm:ssh`, and `vm:doctor` mise tasks
that call gcloud with an explicit configuration, project, zone, and instance.
Keep these values local and leave credentials in gcloud. Start and stop must
handle repeated calls safely. SSH must not start a stopped VM automatically.
See [GCP stop and start](https://docs.cloud.google.com/compute/docs/instances/stop-start-instance)
and [IAP SSH](https://docs.cloud.google.com/compute/docs/connect/ssh-using-iap).

Use manual start and stop by default. An optional runtime cap must use `STOP`
and state that it can interrupt work. A missing SSH session does not prove that
agents or tmux are idle. Stopping loses RAM and running processes; retained
storage and other resources can still incur charges.
