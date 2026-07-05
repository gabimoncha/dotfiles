# Issue Tracker: Local Markdown

Issues and PRDs for this repo live as markdown files in `.scratch/`.

## Conventions

- One effort per directory: `.scratch/<effort-slug>/`
- The PRD is `.scratch/<effort-slug>/PRD.md`
- Implementation issues are `.scratch/<effort-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

Use `docs/agents/triage-labels.md` for the allowed triage status strings.

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<effort-slug>/`, creating the directory if needed.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or issue number directly.

## Wayfinding Operations

Used by `/wayfinder`. The map is a file with one child file per ticket.

- Map: `.scratch/<effort>/map.md` contains notes, decisions so far, and unresolved fog.
- Child ticket: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question or task in the body.
- Ticket type: a `Type:` line records `research`, `prototype`, `grilling`, or `task`.
- Ticket status: a `Status:` line records `claimed` or `resolved`.
- Blocking: a `Blocked by: NN, NN` line near the top means the ticket is unblocked only when every listed ticket is `resolved`.
- Frontier: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- Claim: set `Status: claimed` and save before any work.
- Resolve: append the answer under a `## Answer` heading, set `Status: resolved`, then append a context pointer to the map's decisions so far.
