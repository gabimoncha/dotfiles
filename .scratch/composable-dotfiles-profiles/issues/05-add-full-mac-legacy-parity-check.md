Status: ready-for-agent

# Add Full-Mac Legacy Parity Check

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Add a non-executing parity check that prepares a `full-mac` setup plan and compares its intent against the existing legacy setup sources. This is a regression oracle only; it must not make `full-mac` a runnable profile yet and must not change plain setup behavior.

## Acceptance criteria

- [ ] `full-mac` can be prepared into setup plan files without running setup.
- [ ] A parity check compares prepared `full-mac` intent against legacy root inventory intent for Homebrew, app manifest rows, mise tools/settings, link inventory, checks, and setup flags where applicable.
- [ ] The parity check reports actionable differences with enough detail to fix missing or extra intent.
- [ ] The parity check does not mutate the machine.
- [ ] Plain `./bin/setup` remains the Legacy Setup path.
- [ ] Static validation passes with `git diff --check` and relevant shell syntax checks for any scripts touched.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
- 03-prepare-shared-base-components.md
