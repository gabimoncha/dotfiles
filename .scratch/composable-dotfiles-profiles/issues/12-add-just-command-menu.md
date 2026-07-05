Status: ready-for-agent

# Add `just` Command Menu

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Add `just` as a post-bootstrap command menu that delegates to existing scripts. It should make common profile, dry-run, check, auth, and mobile-dev commands discoverable without becoming a dependency of fresh setup.

## Acceptance criteria

- [ ] `just` is included as a managed tool through the appropriate setup inventory.
- [ ] A Justfile exposes recipes for setup, dry-run, profile inspection, checks, auth, and mobile-dev.
- [ ] Recipes delegate to existing scripts instead of reimplementing setup logic.
- [ ] Fresh setup and bootstrap do not require `just`.
- [ ] The default or help recipe lists available commands clearly.
- [ ] Documentation says `just` is a convenience menu after setup, not the first-run entrypoint.

## Blocked by

- 06-wire-mac-minimal-profile-setup-path.md
