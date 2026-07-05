Status: ready-for-agent

# Extract Mobile Dev As A Component

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Represent mobile development as a Component while keeping the existing mobile development worker profile-unaware. The setup plan should decide whether mobile development runs; the mobile development worker should keep owning its internal Xcode, iOS, Android, and formula sequencing.

## Acceptance criteria

- [ ] Mobile development setup intent is represented as a Component, not a Profile.
- [ ] Setup plan flags indicate whether mobile development should run.
- [ ] The existing mobile development worker remains profile-unaware.
- [ ] `full-mac` preparation includes mobile-dev by default.
- [ ] `--skip-mobile-dev` subtracts only mobile-dev for the current run without changing the selected Profile definition.
- [ ] `mac-minimal` and `mac-robi` mobile-dev behavior matches the approved profile intent matrix.
- [ ] Dry-run output clearly reports whether mobile-dev is included, skipped by profile, or skipped by flag.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
