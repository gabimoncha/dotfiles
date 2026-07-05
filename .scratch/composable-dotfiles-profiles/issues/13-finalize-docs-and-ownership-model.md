Status: ready-for-agent

# Finalize Docs And Ownership Model

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Update owner and agent documentation to explain the final V1 ownership model: Legacy Setup still uses root inventories by default, profile setup prepares setup plan files from profile/component sources, Worker Scripts consume prepared inputs, and generated plan files are inspection/execution inputs rather than source of truth.

## Acceptance criteria

- [ ] README explains plain Legacy Setup and opt-in profile setup separately.
- [ ] README documents the V1 profiles and what each includes or excludes.
- [ ] DECISIONS records the profile/component/setup-plan ownership model and why profile setup remains opt-in in V1.
- [ ] AGENTS guidance tells future agents how to add profile intent without spreading profile rules into Worker Scripts.
- [ ] AGENTS or profile docs tell future agents to inspect existing profiles/components first, compose shared setup intent, and avoid duplicated app/tool/link/check entries.
- [ ] Validation guidance includes deduplication/conflict checks for profile setup plan files.
- [ ] Docs state Linux and Mac mini are out of scope for V1.
- [ ] Docs state `dotfiles-robi` replacement depends on `mac-robi` review and target-machine validation.
- [ ] Docs state local validation on the current Mac is dry-run/static only, and mutating profile setup validation happens on the old Mac or another explicitly approved target.
- [ ] Docs state `just` is a post-bootstrap command menu only.
- [ ] Validation guidance includes profile validation, parity checks, dry-runs, static checks, and target-machine-only mutating validation.

## Blocked by

- 01-define-profile-component-contract.md
- 02-capture-profile-intent-matrix.md
- 03-prepare-shared-base-components.md
- 04-prepare-mac-minimal-plan.md
- 05-add-full-mac-legacy-parity-check.md
- 06-wire-mac-minimal-profile-setup-path.md
- 07-add-sensitive-identity-validation.md
- 08-migrate-reusable-roberta-components.md
- 09-add-mac-robi-end-to-end.md
- 10-extract-mobile-dev-as-component.md
- 11-support-full-mac-profile-setup-path.md
- 12-add-just-command-menu.md
