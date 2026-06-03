---
name: update-use-my-mac
description: Update the dotfiles repo's use-my-mac zsh function and related post-setup command guidance. Use when working in /Users/gabimoncha/development/dotfiles and the user asks to refresh, expand, or sync the use-my-mac/help command menu with aliases, functions, setup follow-up commands, or newly added shell workflows.
---

# Update Use My Mac

## Workflow

1. Work in `/Users/gabimoncha/development/dotfiles` and preserve unrelated dirty worktree changes.
2. Inspect the current shell sources before editing:
   - `home/.config/zsh/aliases.zsh` for aliases.
   - `home/.config/zsh/functions.zsh` for functions and the `use-my-mac` body.
   - `home/.config/zsh/interactive.zsh` for source order.
   - `bin/setup`, `bin/bootstrap`, and README setup sections for post-setup commands worth surfacing.
3. Update `use-my-mac()` in `home/.config/zsh/functions.zsh` so its fzf heredoc reflects the actual aliases, functions, and setup workflows.
4. Preserve the existing UX unless the user explicitly asks to change it:
   - keep the `fzf` dependency guard.
   - keep `alias help='use-my-mac'` in `aliases.zsh`.
   - keep copy-to-clipboard and optional execute behavior.
   - keep argument placeholders such as `<dir>` or `[port]` so execution avoids incomplete commands.
5. Include practical post-setup commands when relevant:
   - `dotfiles`, `dotfiles-update`, `reload-shell`, `edit-profile`.
   - repo scripts such as `./bin/setup`, `./bin/setup --dry-run`, `./bin/auth-setup`, `./bin/install-apps`, `./bin/mackup-restore`, and `./bin/raycast-restore <export.rayconfig>`.
   - local troubleshooting helpers such as `fix-my-network`, `ports`, `portfind <port>`, and `killport <port>`.
6. Keep entries curated and scan-friendly: one command per line, aligned descriptions, no secrets, no machine-local paths beyond the repo's documented defaults.

## Validation

Run the smallest relevant checks after edits:

```bash
zsh -n home/.config/zsh/functions.zsh
zsh -n home/.config/zsh/aliases.zsh
bash -n bin/setup
bash -n bin/bootstrap
bash -n bin/link-dotfiles
git diff --check
```

If setup scripts were touched, also run:

```bash
./bin/setup --dry-run
```

Report any pre-existing dirty files separately from files changed for the task.
