Status: ready-for-agent

# Migrate Reusable Roberta Components

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Use `dotfiles-robi` as read-only migration input and extract only reusable, non-sensitive setup intent into profile/component sources. This should preserve `dotfiles-robi` behavior without copying the fork’s scripts wholesale or importing private identity.

## Acceptance criteria

- [ ] The migration reads `dotfiles-robi` as input and does not mutate that repo or Roberta’s Mac.
- [ ] Reusable Roberta inventory is represented in profile/component sources, not as a separate script fork.
- [ ] The migrated Roberta inventory matches the approved `mac-robi` matrix derived from `dotfiles-robi`.
- [ ] The migrated Roberta inventory excludes Sensitive Identity, including private identity, account-specific paths, tokens, and machine-specific values.
- [ ] Sensitive Identity validation passes on the Roberta component.
- [ ] The migration notes any Roberta behavior intentionally left out of V1.

## Blocked by

- 02-capture-profile-intent-matrix.md
- 03-prepare-shared-base-components.md
- 07-add-sensitive-identity-validation.md
