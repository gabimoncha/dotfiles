# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before Exploring, Read These

- `CONTEXT.md` at the repo root, if it exists.
- `docs/adr/`, if it exists. Read ADRs that touch the area you are about to work in.

If these files do not exist, proceed silently. Do not flag their absence or suggest creating them upfront. The `/domain-modeling` skill, reached through `/grill-with-docs` and `/improve-codebase-architecture`, creates them lazily when terms or decisions actually get resolved.

## File Structure

This is a single-context repo:

```text
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-example-decision.md
│   └── 0002-example-decision.md
└── bin/
```

## Use the Glossary's Vocabulary

When your output names a domain concept in an issue title, refactor proposal, hypothesis, or test name, use the term as defined in `CONTEXT.md`. Do not drift to synonyms the glossary explicitly avoids.

If the concept you need is not in the glossary yet, either reconsider the language or note the gap for `/domain-modeling`.

## Flag ADR Conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding it.
