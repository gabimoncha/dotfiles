Status: ready-for-agent

# Add `mac-robi` End To End

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Add a `mac-robi` Profile that matches the approved `dotfiles-robi`-equivalent matrix. The profile should prepare and dry-run through the profile setup path without inheriting Gabi-specific setup from the current repo. It must not require mutating setup validation on the current Mac.

## Acceptance criteria

- [ ] `mac-robi` is defined as a Profile matching the approved profile intent matrix derived from `dotfiles-robi`.
- [ ] Preparing `mac-robi` writes valid setup plan files.
- [ ] The prepared `mac-robi` plan preserves the approved `dotfiles-robi`-equivalent setup intent.
- [ ] The prepared `mac-robi` plan excludes Gabi app-state restore and Sensitive Identity from the current repo.
- [ ] `mac-robi` dry-run executes through the profile setup path and leaves its plan directory available.
- [ ] Documentation notes that `mac-robi` is intended to replace `dotfiles-robi` only after review and target-machine validation.

## Blocked by

- 06-wire-mac-minimal-profile-setup-path.md
- 08-migrate-reusable-roberta-components.md
