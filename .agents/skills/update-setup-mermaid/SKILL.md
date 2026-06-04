---
name: update-setup-mermaid
description: Update the dotfiles repo README setup-flow Mermaid graph with read-only gpt-5.3-codex medium subagent exploration first. Use when working in /Users/gabimoncha/development/dotfiles and the user asks to refresh, fix, redraw, sync, or validate the README Mermaid diagram that explains bin/setup, bin/bootstrap, install-apps, link-dotfiles, auth, Mackup, Raycast restore, or related setup script flows.
---

# Update Setup Mermaid

## Workflow

1. Work in `/Users/gabimoncha/development/dotfiles` and preserve unrelated dirty worktree changes.
2. Before editing the diagram, use read-only explorer subagents when the multi-agent tool is available:
   - Use model `gpt-5.3-codex` with reasoning effort `medium` if that override exists. If the tool only exposes `gpt-5.3-codex-spark`, use `gpt-5.3-codex-spark` with reasoning effort `medium`.
   - Spawn a flow-mapper subagent: ask it to inspect setup scripts and report direct calls, optional/deferred flows, and exclusions with file/line references.
   - Spawn a README-structure subagent: ask it to inspect the current README Mermaid block and recommend graph placement, container boundaries, and labels that will render cleanly.
   - Keep subagent tasks read-only. Do not delegate edits to subagents for this skill.
   - While subagents run, inspect non-overlapping local context yourself. Integrate their findings before editing.
   - For a pure validation request such as "check whether the graph is current", the helper script may be enough; use subagents when the graph may need to change.
3. Inspect the current setup scripts before editing the diagram:
   - `bin/setup` for top-level orchestration, `--dry-run`, Xcode CLT gates, summary, and interactive follow-up.
   - `bin/bootstrap` for lower-level install flow and calls to `bin/link-dotfiles`, `bin/check-mise-tools`, `bin/setup-tmux`, `macos/defaults.sh`, and Finder sidebar setup.
   - `bin/preflight`, `bin/install-apps`, `bin/install-mobile-dev`, `bin/link-dotfiles`, `bin/auth-setup`, `bin/mackup-restore`, and `bin/raycast-restore` for container internals.
4. Update the Mermaid block under `README.md` -> `### Step 3: Let setup do the unattended work`.
5. Keep the diagram containerized by script:
   - `bin/setup` owns the main control flow.
   - Each called script gets its own `subgraph`.
   - Use dashed arrows for cross-script expansion links so shared scripts do not create misleading returns.
   - Show deferred setup scripts such as `bin/install-mobile-dev` as optional-later dashed links, not as direct setup calls.
   - Keep labels short enough to render cleanly in GitHub Markdown.
6. Keep prep and maintenance scripts out of the main setup graph unless the runtime setup flow actually calls them:
   - Exclude old-Mac prep: `bin/prepare-sync`, `bin/mackup-backup`, `bin/raycast-backup`.
   - Exclude maintenance diagnostics: `bin/app-state-doctor`, `bin/dotfiles-update`.
7. If the current flow still matches the canonical containerized graph, run:

```bash
python3 .agents/skills/update-setup-mermaid/scripts/update_setup_mermaid.py --write
```

8. If setup scripts changed, update both the helper script's canonical graph and the README graph together.

## Validation

Run the smallest relevant checks after edits:

```bash
python3 .agents/skills/update-setup-mermaid/scripts/update_setup_mermaid.py --check
git diff --check
```

If a Mermaid renderer is already available, optionally render the extracted block to catch syntax or layout regressions. Do not install a renderer just for this check unless the user asked for visual validation.
