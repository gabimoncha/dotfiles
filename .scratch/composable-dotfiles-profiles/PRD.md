Status: ready-for-agent

# PRD: Composable Dotfiles Profiles

## Problem Statement

The dotfiles repo currently has one full Mac setup path and a separate `dotfiles-robi` fork for a smaller setup. This creates drift: setup intent is spread across root inventories, worker scripts, hard-coded link lists, restore flows, and a copied minimal repo. The user wants a safer way to compose different Mac setups from reusable pieces without turning setup scripts into branching profile logic.

The immediate need is to prove a profile-based setup path for macOS while preserving the existing plain setup path. Two profile anchors are known now: `full-mac` should match the current repo's legacy setup, and `mac-robi` should match the `dotfiles-robi` repo after excluding sensitive identity. Other profile shapes, including `mac-minimal`, are not decided until the profile intent matrix is drafted and approved. The profile path must keep mobile development as a separate component and keep fresh setup independent of `just`.

## Solution

Introduce opt-in profile-based setup. A selected profile is prepared into setup plan files, and existing worker scripts consume those prepared files. Profile and component composition lives in one deep module. Worker scripts remain focused on installing, linking, checking, or skipping already-prepared setup intent.

Plain `./bin/setup` remains the legacy setup in V1. Profile setup is explicitly selected with a profile name or an existing plan directory. Prepared plan directories are kept under ignored scratch space for inspection after dry-runs and setup runs.

## User Stories

1. As the repo owner, I want plain setup to keep working, so that existing fresh-Mac behavior is not broken while profiles are introduced.
2. As the repo owner, I want to opt into profile setup with a named profile, so that I can test profile behavior without changing the default path.
3. As the repo owner, I want a full Mac profile that matches the current setup intent, so that profile parity can be proven before replacing legacy setup.
4. As the repo owner, I want the minimal Mac profile shape captured in an approved matrix before implementation, so that future agents do not guess what belongs in it.
5. As the repo owner, I want a Roberta-focused Mac profile that matches `dotfiles-robi`, so that the fork can eventually be replaced by equivalent reusable profile inventory in this repo.
6. As the repo owner, I want mobile development to be a component, so that Xcode, simulators, Android tooling, and related local mobile setup can change independently.
7. As the repo owner, I want `--skip-mobile-dev` to keep working for full setup, so that existing lightweight runs still behave as expected.
8. As the repo owner, I want GUI app installation separate from app-state restore, so that a no-GUI profile cannot accidentally restore GUI app state.
9. As the repo owner, I want setup plan files to be left after dry-runs, so that I can inspect what a profile would install, link, check, or skip.
10. As the repo owner, I want setup plan files to be left after real profile runs on an explicitly targeted machine, so that I can debug what happened there.
11. As the repo owner, I want worker scripts to consume prepared inputs, so that profile rules do not spread across setup scripts.
12. As the repo owner, I want a profile validation command, so that invalid profiles fail before setup mutates the machine.
13. As the repo owner, I want plan directory validation, so that rerunning setup from a prepared plan is safe and predictable.
14. As the repo owner, I want sensitive identity validation, so that private account or machine details do not become tracked setup intent.
15. As the repo owner, I want `dotfiles-robi` scanned read-only, so that reusable Roberta inventory can be migrated without mutating Roberta-specific state.
16. As the repo owner, I want `just` as a command menu only, so that common commands are discoverable after bootstrap without becoming a first-run dependency.
17. As a future agent, I want a documented profile contract, so that I know which files are source intent and which files are prepared outputs.
18. As a future agent, I want glossary terms for profile setup, so that profile, component, legacy setup, setup plan files, worker script, setup flags, and sensitive identity stay distinct.
19. As a future agent, I want full-Mac parity checks, so that migration work does not silently change the existing full setup.
20. As a future agent, I want local markdown PRD and issues, so that implementation can be split into ready-for-agent vertical slices.
21. As a future agent, I want duplicate setup intent to be detected or deliberately documented, so that profiles remain composed from shared components instead of drifting into copy-paste inventories.
22. As a future user of Linux support, I want Linux deferred from V1, so that the macOS profile seam can stabilize before adding another platform.
23. As a future Mac mini user, I want Mac mini deferred from V1, so that its exact setup intent can be designed from the proven profile system later.

## Implementation Decisions

- Profile-based setup is opt-in in V1. Plain setup remains the legacy setup path and continues to use current root inventories.
- V1 must include a user-approved profile intent matrix before implementation work begins. The matrix defines what `mac-minimal`, `mac-robi`, and `full-mac` include and exclude, names the source of truth used to derive each row, and marks unresolved cells for user decision rather than guessing. The known anchors are `full-mac = current repo legacy setup` and `mac-robi = dotfiles-robi`.
- Add source directories for profiles and components. Profiles are named setup targets; components are reusable setup intent and are not runnable profiles.
- Profile composition is the required pattern. Profiles select Components; they do not copy another Profile's inventories.
- Use coarse components first: base Mac setup, GUI apps, app-state restore, personal development setup, mobile development, and Roberta-specific reusable setup.
- Add one profile module that owns composition, validation, and preparing setup plan files. Its interface is list, show, validate, and prepare.
- Preparing a profile writes setup plan files: a Homebrew bundle file, app inventory TSV, mise config, link inventory TSV, checks TSV, and setup flags.
- Setup plan directories live under ignored scratch space by default and are preserved after dry-runs and real profile runs.
- Add profile setup entry points for selecting a profile or supplying an existing plan directory.
- Worker scripts consume prepared plan files in profile mode and preserve legacy behavior when no plan is supplied.
- Local validation on the current Mac is dry-run/static only. Mutating profile setup validation must happen on the old Mac or another explicitly approved target machine.
- Preflight remains a quiet setup guard. It validates legacy root files in legacy mode and setup plan files in profile mode.
- Full-Mac parity validation compares prepared full-Mac setup intent with current legacy inventory intent.
- Sensitive identity validation blocks profile/component sources and setup plan files when private account or machine details are found. Legacy root files are warning-only unless actual secrets are detected.
- Profile validation must deduplicate prepared setup intent and report conflicts. Duplicate Homebrew entries, app rows, mise tools/settings, link targets, check commands, and setup flags should either collapse to one effective entry or fail with an explanation when values conflict.
- `dotfiles-robi` is read-only migration input and the source of truth for `mac-robi` behavior. Reusable non-sensitive inventory can enter the Roberta component only after sensitive identity validation.
- The Roberta profile must preserve `dotfiles-robi` setup intent. Any internal factoring such as sharing a base component with `mac-minimal` is an implementation detail that must not change the `dotfiles-robi`-equivalent result.
- Mobile development is a component, not a profile. The existing mobile development worker remains profile-unaware.
- `just` is included in V1 only as a post-bootstrap command menu. Fresh setup cannot require it.
- Documentation must update the repo ownership model: root inventories remain legacy setup sources in V1, while profile/component sources prepare setup plan files for profile setup.
- ADR creation is not mandatory. Add one only if implementation uncovers a surprising, hard-to-reverse tradeoff.

## Testing Decisions

- Profile preparation tests should assert against the approved profile intent matrix, not undocumented expectations in an agent's head.
- Test at the profile module interface. Tests and checks should validate prepared setup plan files, not private renderer internals.
- Validate all profile and component sources with shape checks and sensitive identity checks before setup can use them.
- Validate duplicate and conflicting setup intent at the prepared plan interface, not by relying on agents to visually inspect component files.
- Validate plan directories independently so `--plan-dir` can be trusted without recomputing profile composition.
- Run full-Mac parity checks to prove prepared full-Mac intent matches legacy setup intent.
- Run dry-run setup for each V1 profile on the current Mac and preserve its setup plan directory for inspection.
- Run shell syntax checks for setup scripts and zsh syntax checks for shell files.
- Keep mutating setup validation off the current Mac. Use the old Mac or another explicitly approved target machine before applying profile setup here.
- Verify `just` recipes only delegate to existing scripts and are not required by bootstrap.

## Out of Scope

- Linux setup support.
- Mac mini profile support.
- Making profile setup the default plain setup path.
- Mutating Roberta’s Mac or requiring live validation there.
- Mutating the current Mac during local validation.
- Replacing all legacy root inventories in V1.
- Committing generated setup plan files as source of truth.
- Rewriting mobile development internals.
- Automatically selecting a profile from username, machine name, Apple ID, email, serial, local paths, or other sensitive identity.

## Further Notes

The current glossary lives in `CONTEXT.md`. The key seam is profile preparation: selected profile and components go in, setup plan files come out. Existing worker scripts should stay boring and consume those files without learning profile composition.
