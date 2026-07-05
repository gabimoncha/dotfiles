Status: ready-for-agent

# Wire `mac-minimal` Profile Setup Path

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Wire profile setup support for `mac-minimal` after the approved profile intent matrix defines its shape. Selecting `mac-minimal` should prepare or accept setup plan files, validate them, and have the existing Worker Scripts consume those prepared files while preserving Legacy Setup behavior when no profile is selected.

This slice must not require mutating setup validation on the current Mac. Local validation is dry-run/static only. Any real setup execution belongs on the old Mac or another explicitly approved target machine.

If the approved profile intent matrix defers `mac-minimal` out of V1, this issue should be deferred or rewritten instead of implemented from assumptions.

## Acceptance criteria

- [ ] Setup accepts a profile name and prepares a `mac-minimal` plan before running Worker Scripts.
- [ ] Setup accepts an existing plan directory and validates it before running.
- [ ] Preflight validates legacy root files in Legacy Setup mode and setup plan files in profile mode.
- [ ] Bootstrap consumes the prepared Homebrew bundle file in profile mode.
- [ ] App installation consumes the prepared app inventory TSV in profile mode.
- [ ] Dotfile linking consumes the prepared link inventory TSV in profile mode while preserving backup behavior.
- [ ] Mise checks consume the prepared checks TSV in profile mode.
- [ ] `mac-minimal` dry-run runs through the profile path and leaves the plan directory available.
- [ ] No acceptance criterion requires running mutating setup on the current Mac.
- [ ] Documentation or command output makes clear that real `mac-minimal` setup validation is reserved for an explicitly approved target machine.
- [ ] Plain `./bin/setup` behavior is unchanged.
- [ ] If the approved matrix defers `mac-minimal`, this issue is not implemented as-is.

## Blocked by

- 04-prepare-mac-minimal-plan.md
