---
name: release-notes
description: Explicit-only workflow for updating the native Flow release notes modal from clean version-tag history. Use only when the user invokes $release-notes or directly asks to update the release notes modal bullets.
disable-model-invocation: true
---

# Release Notes

Update only the native release notes modal bullet list at
`apps/native/src/app/release-notes/index.tsx`.

## Workflow

1. Find the previous clean stable tag:
   - Use tags shaped exactly like `vX.Y.Z`.
   - Ignore Expo rebuild tags such as `vX.Y.Z-expo-up-N`.
2. Review all commits from the previous clean tag through `HEAD`.
3. Keep only user-facing features and fixes.
   - Skip refactors, tests, chores, dependency bumps, CI, internal tooling, docs-only changes, and release mechanics.
4. Rewrite `RELEASE_NOTES_BULLETS` with concise user-facing bullets.
   - Keep each bullet to 12 words or fewer.
   - Use plain present-tense product language.
   - Avoid commit hashes, ticket IDs, implementation details, and marketing claims.
5. Do not edit app-store version gating, modal layout, Settings links, or unrelated files unless the user explicitly asks.

## Commands

Use these as a starting point:

```bash
git tag --list 'v*' --sort=-version:refname
git log --oneline <previous-clean-tag>..HEAD
```
