Status: ready-for-agent

# Prepare `mac-minimal` Plan

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Add the first profile preparation path for `mac-minimal` after the user-approved profile intent matrix defines what `mac-minimal` means. Preparing the profile must not mutate the machine or run setup.

If the approved profile intent matrix defers `mac-minimal` out of V1, this issue should be deferred or rewritten instead of implemented from assumptions.

## Acceptance criteria

- [ ] `mac-minimal` is defined as a Profile matching the approved profile intent matrix.
- [ ] If the approved matrix defers `mac-minimal`, this issue is not implemented as-is.
- [ ] The profile module can list, show, validate, and prepare `mac-minimal`.
- [ ] Preparing `mac-minimal` writes the expected setup plan files: Homebrew bundle file, app inventory TSV, mise config, link inventory TSV, checks TSV, and setup flags.
- [ ] Prepared `mac-minimal` plan files match the approved matrix; any exclusion or inclusion is driven by that matrix rather than agent assumptions.
- [ ] Dry preparation leaves the plan directory available for inspection.
- [ ] Prepared plan files pass shape validation.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
- 03-prepare-shared-base-components.md
