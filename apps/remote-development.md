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

`local/t3-dev.compose.yaml.example` is a sanitized deployment example.
Keep the machine-specific copy under ignored `local/t3-dev/` and
upload its `compose.yaml` to the existing NAS Container Manager project folder.
Replace the documentation-only LAN address and public-key placeholder first.
Do not commit actual host addresses, identities, keys, or pairing links.

The example preserves the existing named home and SSH host-key volumes and
workspace bind mount. The compose file does not install T3 or the agent CLIs;
`./bin/setup` installs them in the persistent home (see "Dotfiles on the box").
Install `bin/t3-dev-supervise` there as `~/.local/bin/t3-supervise` (mode 0700). The
container starts it as that user. Changes take effect on a container restart;
port-mapping changes require a project rebuild. Do not delete persistent volumes.

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
The container/project remain `t3-dev`, and the base image remains Node.js on
Debian. This account rename does not change installed runtimes or privileges.

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
normal setup there; it detects Linux and runs every stage in one run:

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
