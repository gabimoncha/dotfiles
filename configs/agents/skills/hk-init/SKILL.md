---
name: hk-init
description: Initialize hk (https://hk.jdx.dev) git hooks in a repository with mise integration. Use when the user asks to set up hk, add pre-commit hooks via hk, initialize git hooks with mise, or migrate a repo to hk. Adds hk to mise.toml, analyzes the codebase to pick relevant builtin linters (always including the conventional-commit check), installs the required tools via mise, and runs the checks.
---

# hk-init

Set up [hk](https://hk.jdx.dev/) — a git hook and linter runner configured in Pkl — in the current repository, using [mise](https://mise.jdx.dev/) as the source of truth for tool versions.

## Workflow

Follow these steps in order. Do not skip the codebase analysis — the value of the skill is picking the _right_ builtins, not all of them.

### 1. Preconditions

- Confirm the directory is a git repository (`git rev-parse --git-dir`). If not, ask before running `git init`.
- Confirm `mise` is installed (`mise --version`). If not, stop and tell the user to install it first.
- If an `hk.pkl` already exists, ask the user whether to regenerate or extend it.
- This skill targets **hk 2.x**. If the repo has v1 config — `hk.toml`/`hk.yaml`/`hk.json`, a project `.hkrc.pkl`, `UserConfig.pkl`, package URLs at `v1.*`, or builtin variants like `gitleaks_staged` — treat the task as a migration. See "Migrating from hk 1.x" at the end of `references/pipeline.md`.

### 2. Add hk to mise.toml

Edit (or create) `mise.toml` in the repo root. `HK_MISE=1` wraps the git hooks with `mise x` so hooks run with mise-managed tools on PATH even if the developer hasn't activated mise:

```toml
[tools]
hk = "latest"

[env]
HK_MISE = 1
```

hk 2 evaluates `hk.pkl` with its bundled pklr evaluator and never calls the `pkl` CLI. Do not add `pkl` for hk itself — add it only if you select the `pkl`/`pkl_format` builtins.

Preserve any existing content in `mise.toml` — merge these entries, don't overwrite. Prefer pinning `hk` to the current latest version (check with `mise latest hk`) instead of `"latest"` if the repo pins its other tools.

Then run `mise install` so `hk` is available. Hook installation is step 7.

### 3. Analyze the codebase and select builtins

hk ships 150+ builtins (`hk builtins` lists them all; sources live in hk's repo under `pkl/builtins/`). Inspect the repo — file extensions, manifests, config files — and select only the builtins that match.

**Default to the modern subset** — the fast, single-binary, mostly Rust/Go tools that replace the older Node/Python-runtime linters. Use a legacy tool only when the repo already commits to it.

**Read `references/modern-builtins.md` before choosing steps.** It holds the full selection tables — always-on steps, the evidence → builtin mapping, the legacy → modern swap list, per-tool caveats, formatter-overlap rules, and the exact `mise.toml` install lines (including the handful of tools that need a `cargo:`/`npm:` backend).

The short version of the defaults:

| Domain     | Use                          | Not                                 |
| ---------- | ---------------------------- | ----------------------------------- |
| JS/TS      | `ox_lint` + `oxfmt`          | `eslint` + `prettier`               |
| Python     | `ruff` + `ruff_format`, `ty` | `black`, `flake8`, `isort`, `mypy`  |
| Markdown   | `rumdl` + `rumdl_format`     | `markdown_lint`                     |
| YAML       | `ryl`                        | `yamllint`                          |
| TOML       | `tombi` + `tombi_format`     | `taplo`                             |
| Go         | `golangci_lint`, `go_fumpt`  | `go_fmt` + `go_vet` + `staticcheck` |
| Spelling   | `typos`                      | codespell / cspell                  |
| GH Actions | `jactionlint` 2.2.0          | `actionlint` + `zizmor`             |

Plus, always: `check_conventional_commit` (commit-msg), `check_merge_conflict`, `trailing_whitespace`, `newlines`, `check_added_large_files`, `gitleaks`, `detect_private_key`.

Two rules that decide most of the hard cases:

- **Existing config wins.** If the repo already has `.eslintrc*`/`eslint.config.*` with custom plugins, `.prettierrc`, `.markdownlint*`, `.yamllint`, `mypy.ini`, `biome.json`, or `.golangci.yml`, use the matching builtin instead of swapping it out underneath the team. Name the modern alternative in your final report and let them decide. (oxlint in particular does not yet cover type-aware `@typescript-eslint` rules.)
- **One formatter per file type.** `oxfmt` also claims markdown, YAML, TOML, JSON, CSS and HTML by default — narrow its `glob` when `rumdl_format`/`tombi_format`/`ryl` are also selected. See the reference for the exact override.

Don't add linters for languages that appear only incidentally (a single script, vendored code). Builtin names in Pkl are snake_case (`Builtins.ruff_format`, `Builtins.ox_lint`).

### 4. Order the steps

hk runs every step in a hook in parallel, coordinated by per-file read/write locks. The locks make that _safe_; they don't make it _sensible_. Steps still need ordering wherever one rewrites a file another reads.

**Read `references/pipeline.md` for the tier model, the two ordering primitives, and a complete validated `hk.pkl` to copy from.** The pipeline in five tiers:

1. **Gatekeepers** — never mutate: `check_merge_conflict`, `check_added_large_files`, `gitleaks`. No ordering.
2. **Content fixers** — change what the code says: `ruff`, `ox_lint`, `rumdl`, `typos`, `jactionlint`.
3. **Formatters** — change only how it looks: `ruff_format`, `oxfmt`, `rumdl_format`, `tombi_format`, `shfmt`. Each `depends` on the tier-2 step sharing its glob.
4. **Whole-repo hygiene** — `trailing_whitespace`, `newlines`. Their globs overlap everything, so they go last, inside one `Group` barrier.
5. **Validators** — read-only, must see the final bytes: `tsc`, `ty`, `cargo_clippy`, `shellcheck`, `knip`.

Formatting is deliberately _after_ lint-fixing, not before. The goal is the same one behind "format first" — never lint a file that's about to be reformatted — but lint autofixers emit unformatted code (`ruff check --fix` removes an import and leaves a blank line; `oxlint --fix` rewrites an expression without re-wrapping). Formatting last is what makes the run's output format-stable; formatting first would commit unformatted code and reformat it on the next run forever. It's also why Astral documents `ruff check --fix` → `ruff format`, and why hk's own bundled example puts `prettier` behind `depends = List("eslint")`. In check-only runs nothing mutates, so the order affects only which failure prints first.

Use `depends = List("<step-key>")` to order two steps that share a glob — it costs nothing, everything else keeps running in parallel. Use `exclusive = true` (or a `Group`) only for steps whose glob is genuinely repo-wide, since it's a full barrier.

### 5. Write hk.pkl

Run `hk init --mise` to scaffold, or write `hk.pkl` directly, using the reference pipeline as the skeleton and dropping the tiers that don't apply. Pin the version in the package URLs to the installed hk version (`hk --version`).

In hk 2, a top-level `steps` block creates the `check`, `fix`, and `pre-commit` hooks for you, with these defaults:

- `pre-commit` fixes, stages the fixed files, and uses git stashing.
- `fix` fixes but does **not** stage (pass `--stage` to stage).
- `check` only checks.

Only hooks that need something different are written under `hooks`:

```pkl
amends "package://github.com/jdx/hk/releases/download/vX.Y.Z/hk@X.Y.Z#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/vX.Y.Z/hk@X.Y.Z#/Builtins.pkl"

steps {
    ["gitleaks"] = Builtins.gitleaks                                    // tier 1
    ["typos"] = (Builtins.typos) { exclusive = true }                   // tier 2, repo-wide
    ["ruff"] = Builtins.ruff                                            // tier 2
    ["ruff-format"] = (Builtins.ruff_format) { depends = List("ruff") } // tier 3
    ["hygiene"] = new Group {                                           // tier 4
        steps {
            ["trailing-whitespace"] = Builtins.trailing_whitespace
            ["newlines"] = Builtins.newlines
        }
    }
    ["ty"] = Builtins.ty                                                // tier 5
}

hooks {
    ["commit-msg"] {
        steps {
            ["conventional-commit"] = Builtins.check_conventional_commit
        }
    }
}
```

- Do not add `pre-commit`, `check`, or `fix` hooks just to repeat the shared steps. If you write one of these hooks explicitly, its hook-level settings apply, its steps replace shared steps with the same key, and the other shared steps still run.
- hk 2 creates no implicit `pre-push`. To add one, write `["pre-push"] { steps { ...module.steps } }`.
- Customize a builtin by amending it, e.g. `["oxfmt"] = (Builtins.oxfmt) { glob = List("**/*.ts", "**/*.tsx") }`. Builtin variants are now typed options on the primary builtin: `(Builtins.gitleaks) { scan = "staged" }`, `(Builtins.knip) { strict = true }`, `(Builtins.pinact) { version = "3" }`.
- Set `enabled = false` on a hook to skip it and leave it out of `hk install`.

Verify the ordering came out as intended: `hk fix --all -v` prints the resulting barriers as `running group: 0…N`.

### 6. Add the linter tools to mise.toml

For every selected builtin that needs an external tool, add it to `[tools]` in `mise.toml`, then run `mise install`. The exact install lines — including which tools need a `cargo:`/`npm:` backend because they aren't in the mise registry — are in `references/modern-builtins.md` under "mise install lines".

Skip tools already provided by the project (e.g. eslint/prettier in `package.json` devDependencies — hk will find them via the project's node_modules when run through mise).

Verify each tool resolves before writing it into `hk.pkl`: `mise x -- <tool> --version`. If a tool won't install on the user's platform, drop that step rather than shipping a hook that fails for everyone.

### 7. Install the hooks and run the checks

Choose the install scope from the git version (`git --version`):

- **Git 2.54 or later — global install (recommended by hk).** `hk install --global --mise` installs the hooks one time per machine in `~/.gitconfig`. In a repository without hk config, the hook does nothing. This changes the user's global git config, so ask before you run it. If a global hk install already exists, `hk install` in the repo skips the local install. That is correct — do not force a local install.
- **Older git, or the user wants repo-scoped hooks.** Run `hk install --mise`. For teammates, add this to `mise.toml` so `mise install` also installs the hooks:

  ```toml
  [hooks]
  postinstall = "hk install --mise"
  ```

  A repo-scoped install needs `mise` on git's runtime `PATH`.

Then run the checks:

```sh
hk check --all      # run every linter across the whole repo
```

- If `hk check --all` reports fixable issues, run `hk fix --all`, show the user the diff, and re-run `hk check --all`. `hk fix` does not stage in hk 2, so the fixes stay as unstaged changes.
- If a specific linter fails due to missing project config or an unfixable pre-existing issue, report it; offer to either fix the findings or narrow/remove that step rather than leaving a hook that blocks every commit.
- Test the commit-msg hook without committing: `echo "bad message" | hk util check-conventional-commit /dev/stdin` should fail, `feat: example` should pass.

### 8. Report

Summarize for the user: which builtins were selected and why, which tools were added to `mise.toml`, which install scope you used, and the result of `hk check --all`. Tell them what teammates must do: with a global install, each teammate runs `hk install --global --mise` one time on their machine. With the `postinstall` hook, `mise install` is sufficient.
