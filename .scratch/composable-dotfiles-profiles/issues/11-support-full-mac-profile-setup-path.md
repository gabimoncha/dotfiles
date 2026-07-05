Status: ready-for-agent

# Support Full-Mac Profile Setup Path

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Make `full-mac` a supported opt-in Profile path after parity checking exists. Selecting the `full-mac` Profile should use prepared setup plan files and preserve the current legacy behavior as closely as possible, while plain setup remains the Legacy Setup path.

This slice must be validated locally with dry-run/static checks only. Mutating `full-mac` profile setup validation belongs on the old Mac or another explicitly approved target machine before it is ever applied on the current Mac.

## Acceptance criteria

- [ ] `full-mac` can be selected explicitly as a Profile setup path.
- [ ] `full-mac` setup uses prepared setup plan files for Homebrew, app inventory, mise config, link inventory, checks, and setup flags.
- [ ] Existing mobile-dev default behavior is preserved for explicit `full-mac` profile runs.
- [ ] `--skip-mobile-dev` works for explicit `full-mac` profile runs.
- [ ] The full-Mac parity check passes or reports only documented intentional differences.
- [ ] Plain `./bin/setup` remains the Legacy Setup path in V1.
- [ ] Dry-runs keep their plan directories available for inspection on the current Mac.
- [ ] Real `full-mac` profile setup validation is documented as target-machine-only, not a current-Mac validation step.

## Blocked by

- 05-add-full-mac-legacy-parity-check.md
- 06-wire-mac-minimal-profile-setup-path.md
- 07-add-sensitive-identity-validation.md
- 10-extract-mobile-dev-as-component.md
