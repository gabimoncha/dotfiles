<!--
Write for a reviewer who will not open the files. Short prose.
Delete any section that does not apply.
-->

## Why

<!--
One or two sentences. Name the problem, the advisory (CVE or GHSA), or the
setup stage that failed.
-->

## What changes

<!--
One picture. Pick the smallest view that makes the point:
- A Mermaid flowchart when the change adds, removes, or reorders setup
  steps, for example a stage in the macOS or Linux plan of `bin/setup`.
  Boxes are steps, arrows mean "then", and diamonds are decisions.
- A Mermaid state diagram (stateDiagram-v2) when the change adds or changes
  states, for example the result of a setup stage (passed, failed, blocked,
  deferred) and the events that move between them.
- A table for version changes: tool, old version, new version, and the
  platforms it installs on (macOS, Linux, or both).
- For other changes: a diff of a file, a link map (source under `home/` to
  target under HOME), or the command output a user sees.
Add up to three bullets for what the picture misses, including what you
left out on purpose.
-->

**Look at:** <!-- the one file or decision that needs a careful look -->

## Evidence

<!--
This repo has no CI. List the checks that you ran and their results:
- `bash -n` or `zsh -n` on each changed shell file.
- `./bin/preflight`.
- `git diff --check`.
- For a setup or app-install change, the matching dry run, for example
  `./bin/setup --dry-run`, `./bin/setup --continue --dry-run`, or
  `./bin/install-apps --dry-run`.
- For a shared file, the same checks on a Linux host (Debian or Ubuntu),
  if you could reach one.
- Any other probe, for example a lockfile check, a checksum, or a
  `--version` from the new binary.

Then state what stays unchecked on a real Mac and on Linux, for example a
fresh install, a live tool reinstall, or a Linux run. Do not validate with
live installs, account changes, personal restores, or macOS defaults.
-->

## Merge danger

**Door:** <!-- one-way (hard to undo: live files under HOME, deleted tool versions, macOS defaults, Keychain, backups) or two-way (a revert and a rerun of setup fix it) -->
**Blast radius:** <!-- one word, e.g. none, Mac, Linux, both, shell, editor -->

<!--
One or two sentences on what could break and on which platforms. A shared
file (`home/` files that both systems link, `bin/` scripts that both setups
run, the mise tool list) runs on macOS and on Linux. Name changes to link
backups or user state, setup reruns, `mise prune`, the lockfile, and
anything near credentials (SECURITY.md).
-->

## After merge

<!--
Manual steps in order, and on which hosts: `dotfiles-update` or
`git pull`, `mise install`, a rerun of `./bin/setup` or
`./bin/setup --continue`, `harness update`, a new shell, or a manual app or
System Settings step. Delete if none.
-->
