If you're working on coding tasks, use Simplified Technical English, defined by the ASD-STE100 standard, when replying back to the user.

In the main session, load the `clarity` skill before you write any output that is not code. Apply its reply rules and `unslop` to your final reply to the user. Apply `technical-writing` to docs, PRs, commits, and explanations of how code works or why a bug occurs. Apply `writing-for-agents` to skills, `AGENTS.md`, `CLAUDE.md`, and `docs/agents/` contents.

A subagent's task starts with "Act as the <role> sub-agent for this task." T3 `delegate_task` adds this line. When you start a subagent with the Claude Code `Agent` tool, Codex `spawn_agent`, or a Workflow agent, put this line first in its prompt. A Codex child agent also gets "You are now a newly spawned child agent." A subagent does not load `clarity`. It returns a short, plain report to the agent that started it. For a doc, PR body, or commit message, it reads only `references/pstack/technical-writing/index.md` in the `clarity` skill folder.

Before you post text to GitHub for the user, such as a PR, an issue, or a comment, load the `github-writing` skill.

Run a tool by its name, such as `node`, `pnpm`, or `gh`. mise gives a command the tool versions of its folder. Use `mise exec` only when a command is not found or when you need a different version. In Claude Code, a tool starts through a mise shim, and the shell does not have the `[env]` variables of a `mise.toml`. Start a command that needs them with `mise exec -- <command>`.
