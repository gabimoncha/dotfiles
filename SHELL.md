# Shell usage

Zsh entrypoints load modules from `configs/zsh/`: environment for every
shell, profile/PATH for login shells, and interactive tools, aliases and
functions for interactive shells. Optional integrations use installed
executables; prompt startup does not provision tools or fetch credentials.
Open a new terminal after changing configuration.

## Local configuration and accounts

Put local exports and secrets in ignored `~/.config/local/*.zsh` or
`local/*.zsh`. Start from
[secrets.zsh.example](local/secrets.zsh.example).
Use the zsh `path` array for tracked PATH changes; keep private values out of Git.

Git commit identity, SSH identity, and GitHub API identity are separate.
Use `~/.gitconfig.local` for conditional Git identities and `~/.ssh/config`
for per-account hosts. The managed `~/bin/gh` wrapper selects a stored API
account for one command without switching the global active account:

```bash
cp local/github-account-routing.example local/github-account-routing
```

Edit the copy with tab-separated values. `default` selects the usual account;
`route` maps a directory to another account. Linked worktrees also match through
the shared Git directory. `gh auth` and explicit `GH_TOKEN`/`GITHUB_TOKEN`
bypass routing. Git push/pull use SSH configuration independently.

## Command helpers

Run `use-my-mac` (or `help`) for the searchable command menu. It copies commands
and can execute the selected entry after confirmation. Implementations are in
[functions.zsh](configs/zsh/functions.zsh) and
[aliases.zsh](configs/zsh/aliases.zsh).

`commit-ai` / `gcai` asks Codex for a Conventional Commit subject from the staged
patch, then opens it in Neovim before Git hooks run. Save with `:wq` to commit
using the edited message; quit the untouched buffer with `:q` to abort.
The helper runs Codex ephemerally in a read-only sandbox.

`infisical-work` and `infisical-personal` support `run`, `export`, and `secrets`.
They read the corresponding `INFISICAL_WORK_TOKEN` / `INFISICAL_PERSONAL_TOKEN`
and optional `*_API_URL` from local configuration. For example:

```zsh
infisical-work run --env=dev -- bun dev
infisical-personal secrets get SOME_KEY --env=dev
```

## Package runners

`npx` / `px` uses mise's resolved `[settings.npm].package_manager` setting.
The global choice is Bun; projects can override it to pnpm or aube.
Bun delegates to `bunx`; pnpm uses a local `node_modules/.bin` command when
present, otherwise `pnpm dlx`. `bx` selects Bun explicitly; `npx!` selects the
real npm runner through Socket Firewall Free.

Interactive aliases wrap `npm`, `pnpm`, `yarn`, `pip`, `uv`, and `cargo` with
Socket Firewall Free when it is available. `command <tool>` bypasses an alias.
Bun/Bunx and noninteractive installers do not inherit that protection.
See [execution policy](SECURITY.md#what-setup-trusts) for its limits.
When shims are absent from PATH, use `mise exec -- <command>`.

## tmux over SSH

An interactive SSH login to a host with these dotfiles attaches to a tmux
session that has no client. With no free session, it creates `main`, or a
numbered session when `main` is in use. The session keeps running when the
connection drops or you close the terminal, and the next login gets it back.
When several connections drop at once, a login can get another free session
than before. `prefix d` detaches and ends the SSH connection. `exit` in the
last window closes the session. The prefix is `Ctrl-a`. Run
`ssh -t HOST zsh` for a shell outside tmux, or
`ssh -t HOST tmux new-session -A -s NAME` for a named session.

From a tmux on your Mac, the remote session hides its status bar and has no
prefix, so you see one tmux and `Ctrl-a` goes to the Mac tmux. The remote host
sees the Mac tmux in `TERM` (`tmux-*` or `screen-*`). Each Mac window that runs
`ssh HOST` has its own remote session. In such a window, `prefix c`, `prefix H`,
and `prefix V` open another `ssh HOST` in a new window or split
([tmux-ssh-split](https://github.com/pschmitt/tmux-ssh-split)), which gets its
own remote session. On macOS the plugin repeats a remote command, such as
`uptime` in `ssh HOST uptime`, instead of removing it. Scroll the remote
history with the mouse: the Mac tmux scrollback does not hold it. From a plain
terminal tab or a phone, the remote session shows its status bar and uses
`Ctrl-a`.

The status bar runs the tmux-continuum autosave, so a hidden bar stops it. tmux
also saves the sessions with tmux-resurrect at each detach, which includes a
dropped connection. A container restart ends the sessions; tmux-resurrect
restores their windows, but not the programs that ran in them. On the Mac,
tmux-resurrect also starts the ssh panes again, and each one logs in to a free
remote session.

## Android

On macOS, the configuration sets `JAVA_HOME` to Zulu 17 and `ANDROID_HOME` to
`~/Library/Android/sdk`; it adds JDK, emulator and platform-tools paths.
Android Studio installs SDK packages and creates emulator images.
To inspect the debug signing SHA-1:

```bash
keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## Coding agent updates

`harness update` updates Codex, Claude Code, Pi and its packages, OpenCode v2,
and Cursor Agent. Vendor updates run in parallel. The T3 Code desktop app
updates itself and its `t3` command. On Linux, the T3 app updates the T3
server. A failure does not stop other
updates, and the command returns nonzero when any update fails.

In interactive zsh, the `mise` helper runs the updater for installed agents
after a successful `mise install`, `mise up`, or `mise up --local`.
It also runs when no mise tools change. After `mise up`, or
`mise install` without tool names, the helper first deletes the unused
versions of the tools in the global config (`mise prune --tools TOOL...`). Help and dry-run commands do not
update agents. `command mise` bypasses the shell helper and does not update
agents. Package resolution, `mise exec`, and shim calls do not start agent updates.
