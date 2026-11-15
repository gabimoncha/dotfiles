# Step ordering

hk runs every step in a hook **in parallel**, using per-file read/write locks so two
linters never corrupt the same file. Locking makes parallel execution _safe_; it does not
make it _sensible_. Ordering is still needed whenever one step's output is another step's
input.

## The one rule that determines the order

**A step that rewrites a file must finish before a step that reads or rewrites the same
file.** Everything else can run in parallel.

That yields five tiers. Only tiers 2→4 need explicit ordering; tier 1 and tier 5 fall out
of it.

| Tier | What                                         | Examples                                                                                                             | Ordering                                             |
| ---- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1    | Gatekeepers — never mutate                   | `check_merge_conflict`, `check_added_large_files`, `gitleaks`, `detect_private_key`, `hadolint`, `dclint`, `lychee`  | none — let them run in parallel                      |
| 2    | Content fixers — change what the code _says_ | `ruff`, `ox_lint`, `rumdl`, `typos`, `shellharden`, `pinact`, `jactionlint`, `golangci_lint --fix`                   | before tier 3 on the same files                      |
| 3    | Formatters — change only how it _looks_      | `ruff_format`, `oxfmt`, `rumdl_format`, `tombi_format`, `ryl`, `yamlfmt`, `shfmt`, `cargo_fmt`, `go_fumpt`, `stylua` | `depends` on the tier-2 step that shares its glob    |
| 4    | Whole-repo hygiene                           | `trailing_whitespace`, `newlines`, `mixed_line_ending`, `byte_order_marker`                                          | after all of tier 3 — their globs overlap everything |
| 5    | Validators — read-only, need final bytes     | `tsc`, `ty`, `mypy`, `cargo_clippy`, `cargo_check`, `shellcheck`, `selene`, `tombi`, `knip`, `sherif`, `vacuum`      | after tier 4                                         |

## Why formatters run _after_ lint-fixers, not before

The intuition "format first, then lint" is right about the goal — never lint a file that
is about to be reformatted — but the wrong way to reach it, because **lint autofixers emit
unformatted code**. `ruff check --fix` deletes an unused import and leaves a blank line;
`oxlint --fix` rewrites an expression without re-wrapping the line. If the formatter ran
first, the run would _end_ with the file unformatted, and the pre-commit hook would commit
it that way. Next run reformats it — permanent churn.

Formatting last makes the output **format-stable**: whatever the fixers emitted is
normalized before the run ends. This is why Astral documents `ruff check --fix` then
`ruff format`, why `eslint-config-prettier` exists, and why hk's own bundled example puts
`prettier` behind `depends = List("eslint")`.

The user-facing goal is still met, from the other direction: formatters never report
"issues" that a lint step would have flagged — they just fix them — so nobody reads lint
output about a file that's about to change shape.

In **check mode** (`hk check`, `pre-push`, CI) nothing mutates, so the order does not
affect the result at all. It only affects which failure you read first. Set
`fail_fast = true` if you want the cheapest step to be the one that stops the run.

## The two ordering primitives

| Primitive           | Use for                                                                  | Cost                                           |
| ------------------- | ------------------------------------------------------------------------ | ---------------------------------------------- |
| `depends = List(…)` | Ordering two steps that share a glob (`oxfmt` after `ox_lint`)           | none — everything else still runs in parallel  |
| `exclusive = true`  | A step whose glob overlaps _everything_ (`typos`, `trailing_whitespace`) | a full barrier: nothing else runs alongside it |

A `Group` is the same barrier as `exclusive`, but lets several steps share it and run in
parallel with each other. Use it for the tier-4 hygiene pair.

Prefer `depends`. Reach for a barrier only when a step's glob is genuinely repo-wide —
otherwise you serialize the whole hook for no reason.

## Reference pipeline

This example uses hk 2.5.0. Run `hk validate` and `hk fix --all -v` to check
the config and its group sequence in the target repository.

```pkl
amends "package://github.com/jdx/hk/releases/download/v2.5.0/hk@2.5.0#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/v2.5.0/hk@2.5.0#/Builtins.pkl"

steps {
    // ── tier 1: gatekeepers. Never mutate, no ordering needed. ──
    ["check-merge-conflict"] = Builtins.check_merge_conflict
    ["check-added-large-files"] = Builtins.check_added_large_files
    ["gitleaks"] = Builtins.gitleaks

    // ── tier 2: content fixers. `typos` is repo-wide, so it takes the barrier. ──
    ["typos"] = (Builtins.typos) { exclusive = true }
    ["jactionlint"] = new Step {
        glob = List(".github/workflows/*.yml", ".github/workflows/*.yaml",
                    ".github/actions/**/action.yml", ".github/actions/**/action.yaml",
                    ".github/dependabot.yml", ".github/dependabot.yaml")
        check = "jactionlint --format gcc {{files}}"
        fix = "jactionlint --fix {{files}}"
        batch = true
    }
    ["oxlint"] = Builtins.ox_lint
    ["ruff"] = Builtins.ruff
    ["rumdl"] = Builtins.rumdl

    // ── tier 3: formatters. Each waits only on the fixer sharing its files. ──
    ["oxfmt"] = (Builtins.oxfmt) {
        depends = List("oxlint")
        // narrowed so rumdl_format owns markdown and tombi_format owns TOML
        glob = List("**/*.js", "**/*.mjs", "**/*.cjs", "**/*.ts", "**/*.mts", "**/*.cts",
                    "**/*.jsx", "**/*.tsx", "**/*.json", "**/*.jsonc", "**/*.css", "**/*.html")
    }
    ["ruff-format"] = (Builtins.ruff_format) { depends = List("ruff") }
    ["rumdl-format"] = (Builtins.rumdl_format) { depends = List("rumdl") }
    ["tombi-format"] = Builtins.tombi_format

    // ── tier 4: whole-repo hygiene. One barrier, both steps inside it. ──
    ["hygiene"] = new Group {
        steps {
            ["trailing-whitespace"] = Builtins.trailing_whitespace
            ["newlines"] = Builtins.newlines
        }
    }

    // ── tier 5: validators. Defined after the barrier, so they see final bytes. ──
    ["tsc"] = Builtins.tsc
    ["ty"] = Builtins.ty
    ["tombi"] = Builtins.tombi
}

hooks {
    ["commit-msg"] {
        steps {
            ["conventional-commit"] = Builtins.check_conventional_commit
        }
    }
    ["pre-push"] {
        // check only — no implicit pre-push in hk 2, so spread the shared steps
        steps { ...module.steps }
    }
}
```

The top-level `steps` block creates the `check`, `fix`, and `pre-commit` hooks, so they
are not written out. `pre-commit` fixes, stages, and stashes; `fix` fixes without
staging; `check` only checks. Only `commit-msg` (different steps) and `pre-push` (no
implicit hook in hk 2) need a `hooks` entry.

`hk fix --all -v` on that config prints the resulting barriers as `running group: 0…3`:
typos alone, then the lint/format tier, then hygiene, then validators. Use that output to
verify the ordering came out as intended after any edit.

## Ordering pitfalls

- **Only order what overlaps.** `oxfmt` has no reason to wait on `ruff`. A `depends` chain
  across unrelated languages turns a parallel hook into a sequential one.
- **`depends` names steps, not builtins.** The string must match the key you used in the
  `steps` block (`"oxlint"`, not `"ox_lint"`).
- **A barrier splits everything after it.** Every step defined below an `exclusive = true`
  step lands in a later group, even ones you meant to run early. Define tier 1 above the
  first barrier.
- **`check_first` (default `true`) is already an optimization**, not an ordering tool: hk
  runs the check with read locks and only escalates to the fix with write locks if it
  fails. Leave it on.
- **`stomp = true`** skips the file locks entirely. Only for tools with their own locking
  (`tsc`, `mypy` on a whole project) — never on a step that writes files.
- **`batch = true`** parallelizes a single-threaded linter across file chunks. Safe with
  formatters and worth setting on the slow ones; irrelevant to ordering.

## Migrating from hk 1.x

hk 2 loads Pkl only and fails with an error that names the replacement for each removed
input. Full guide: <https://hk.jdx.dev/migration-v2>.

| hk 1.x                                                       | hk 2                                                            |
| ------------------------------------------------------------ | --------------------------------------------------------------- |
| `local linters` spread into `pre-commit`/`check`/`fix`       | one top-level `steps { … }` block; delete those three hooks     |
| `fix = true` + `stash = "git"` on `pre-commit`               | default for the implicit `pre-commit`; delete                   |
| `hk fix` stages its fixes                                    | `hk fix` does not stage; pass `--stage` or set `stage = true`   |
| `Builtins.gitleaks_staged`                                   | `(Builtins.gitleaks) { scan = "staged" }`                       |
| `Builtins.knip_strict`                                       | `(Builtins.knip) { strict = true }`                             |
| `Builtins.pinact_v3`, `Builtins.pinact_update_v3`            | `(Builtins.pinact) { version = "3" }`, same for `pinact_update` |
| `Builtins.check_byte_order_marker` / `fix_byte_order_marker` | `Builtins.byte_order_marker`                                    |
| `hk.toml`, `hk.yaml`, `hk.yml`, `hk.json`                    | `hk.pkl` amending `Config.pkl`                                  |
| project `.hkrc.pkl`                                          | `hk.local.pkl`                                                  |
| `~/.hkrc.pkl`, `--hkrc <PATH>`                               | `~/.config/hk/config.pkl`                                       |
| `UserConfig.pkl` (`environment { }`, `defaults { }`)         | `Config.pkl` with `env { }` and top-level settings              |
| `Types.Regex(…)`, `Config.Regex(…)`                          | Pkl's built-in `Regex(…)`                                       |
| `hk generate`                                                | `hk init`                                                       |
| `HK_PKL_BACKEND=pkl`, `pkl` in `mise.toml` for hk            | remove; hk uses its bundled evaluator                           |

A `stage` list on a step is now only a path filter. It does not turn on staging by
itself. After the migration, bump the package URLs to the installed version and run
`hk validate`.
