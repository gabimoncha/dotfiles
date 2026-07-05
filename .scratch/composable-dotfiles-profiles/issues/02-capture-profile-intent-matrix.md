Status: ready-for-human

# Draft And Approve Profile Intent Matrix

## Parent

.scratch/composable-dotfiles-profiles/PRD.md

## What to build

Create an explicit profile intent matrix that future agents can use without re-grilling the user during implementation. The matrix should define what `mac-minimal`, `mac-robi`, and `full-mac` include and exclude across setup concerns such as Homebrew, GUI apps, app-state restore, mise tools/settings, dotfile links, checks, setup flags, auth, Touch ID, standalone installers, mobile-dev, and sensitive identity.

The currently known anchors are narrow: `full-mac` should match the current repo's Legacy Setup, and `mac-robi` should match `dotfiles-robi` after excluding Sensitive Identity. The rest, including the exact `mac-minimal` shape and any proposed shared base factoring, is not decided until this matrix is drafted and approved.

This is a review gate, not an implementation slice. The agent should derive a draft from repo sources, `dotfiles-robi`, the PRD, and `CONTEXT.md`; mark any undecided cells as `needs user decision`; then stop and ask the user to approve or correct the matrix before downstream implementation issues proceed.

## Acceptance criteria

- [ ] A profile intent matrix exists in the profile/component documentation.
- [ ] The matrix covers `mac-minimal`, `mac-robi`, and `full-mac`.
- [ ] The matrix includes at least these concerns: Homebrew formulae, Homebrew casks, Mac App Store apps, manual/vendor apps, GUI app config links, app-state restore, mise tools, mise settings, dotfile links, smoke checks, standalone installers, GitHub auth, Touch ID sudo, mobile-dev, setup flags, and sensitive identity.
- [ ] The first draft is derived from discoverable sources: legacy root inventories, current scripts/docs, `dotfiles-robi` read-only inventory, the PRD, and `CONTEXT.md`.
- [ ] `full-mac` is documented as current repo Legacy Setup intent, with mobile-dev included by default if that is what legacy setup currently does, and `--skip-mobile-dev` subtracting only that component for the current run.
- [ ] `mac-robi` is documented as `dotfiles-robi`-equivalent setup intent, with Sensitive Identity excluded and any deviations explicitly marked for user approval.
- [ ] `mac-minimal` is marked `needs user decision` except for any cells the user explicitly approves in this matrix.
- [ ] Any proposed factoring such as `mac-robi = mac-minimal + robi` is treated as an implementation proposal, not a known requirement, and must preserve the approved `mac-robi` matrix.
- [ ] Each profile/concern cell names its derivation source or states that it is intentionally excluded/deferred.
- [ ] Any cell that cannot be derived from existing sources is marked `needs user decision`; the agent must not guess those values.
- [ ] The user has approved the matrix before implementation issues depending on this file begin.
- [ ] Future implementation issues refer to this approved matrix instead of asking the user to restate profile contents.

## Blocked by

- 01-define-profile-component-contract.md
