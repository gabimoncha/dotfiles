Status: ready-for-agent

# Prepare Shared Base Components

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Create the first real component inventories for the shared macOS setup intent approved in the profile intent matrix. This should capture only the reusable setup intent that the matrix says is shared across profiles.

This slice should make the shared base inventory inspectable and valid against the contract, but it does not need to run setup from a profile yet.

## Acceptance criteria

- [ ] Shared base component inventories are present and documented enough for later profiles to include them.
- [ ] The base inventories include only reusable setup intent approved by the profile intent matrix.
- [ ] The base inventories do not silently encode undecided `mac-minimal` assumptions.
- [ ] Shared setup intent is represented once in an appropriate Component rather than duplicated across Profiles.
- [ ] Existing legacy setup behavior is unchanged when no profile is selected.
- [ ] Static validation passes with `git diff --check` and relevant shell syntax checks for any scripts touched.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
