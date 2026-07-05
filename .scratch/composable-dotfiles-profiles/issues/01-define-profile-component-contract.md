Status: ready-for-agent

# Define Profile And Component Contract

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Define the source contract for profile-based setup before implementation work spreads across scripts. A future agent should be able to read the contract and know what a profile is, what a component is, which setup plan files are prepared, what setup flags are allowed, and which files are source intent versus inspection/execution inputs.

This slice should create the initial profile/component directory structure and documentation, but it should not wire profile execution into setup yet.

## Acceptance criteria

- [ ] Profile and component source directories exist with placeholder or example-free structure appropriate for real inventories.
- [ ] The profile contract documents profile source files, component source files, setup plan files, setup flags, and validation expectations.
- [ ] The contract uses the glossary terms from `CONTEXT.md`: Profile, Component, Legacy Setup, Setup Plan Files, Prepare Profile, Worker Script, Setup Flags, and Sensitive Identity.
- [ ] The contract documents Profile Composition: Profiles select Components rather than copying another Profile's setup intent.
- [ ] The contract states that setup plan files are prepared outputs and must not become committed source of truth.
- [ ] The contract states that Worker Scripts must consume prepared inputs and must not decide profile/component composition.
- [ ] The contract defines deduplication and conflict rules for Homebrew entries, app rows, mise tools/settings, link targets, check commands, and setup flags.
- [ ] Static validation passes with `git diff --check`.

## Blocked by

None - can start immediately
