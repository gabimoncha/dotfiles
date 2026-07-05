Status: ready-for-agent

# Add Sensitive Identity And Deduplication Validation

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Add validation that prevents Sensitive Identity from leaking into profile/component sources or prepared setup plan files, and add validation that catches duplicate or conflicting setup intent. The validation should block new profile-based sources and plans when private identity appears, while keeping legacy root files warning-only unless actual secrets are detected.

## Acceptance criteria

- [ ] Sensitive Identity validation runs on profile sources, component sources, and prepared setup plan files.
- [ ] The validator catches account identifiers, private emails, hard-coded home paths, tokens, serial-like values, and cloud-backup account paths where they would define tracked setup intent.
- [ ] The validator distinguishes likely secrets from benign setup strings enough to avoid noisy failures on legacy root files.
- [ ] Profile preparation fails when sensitive identity is found in profile/component sources or plan files.
- [ ] Legacy root file validation is warning-only unless actual secrets are detected.
- [ ] The validation can be run independently as part of profile validation.
- [ ] Duplicate Homebrew entries, app rows, mise tools/settings, link targets, check commands, and setup flags are detected at the prepared setup plan interface.
- [ ] Exact duplicates collapse to one effective prepared entry or are reported as deliberate duplicates according to the profile contract.
- [ ] Conflicting duplicates fail validation with an actionable message.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
