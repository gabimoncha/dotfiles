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
One picture, with a Before and an After. Draw two diagrams, Before and
After, or draw one diagram and mark the changed parts with
`classDef changed`. For a new thing, write "Before: none."

Pick the diagram with one question: does the next step depend on an input
from outside, which can come late, come wrong, or not come?
- Yes: a Mermaid state diagram (stateDiagram-v2). An outside input is a
  user action, a reply from a service or a device, a webhook, a timer, or
  a cancel. A state is a place where the thing waits, for example a setup
  stage at "Waiting for macOS updates", "Waiting for App Store sign-in",
  or "Waiting for manual approval". End states can be passed, failed,
  blocked, or deferred. An arrow is the event that moves it on. Draw the
  arrows for the bad events too (timeout, error, cancel, retry), because
  the change can go wrong there.
- No: a Mermaid flowchart. The procedure runs from start to end with the
  data that it has, for example a run of `bin/link-dotfiles` or a lockfile
  update. Boxes are steps, arrows mean "then", and diamonds are decisions
  on that data.
- No diagram fits (a tool version bump, a rename, a setting value): a
  table of old and new values, a diff, or pseudocode.
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
file (app sources that both systems use, `bin/` scripts that both setups
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
