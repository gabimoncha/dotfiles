# Modern hk builtin subset

Curated from `hk builtins` (hk 2.5.0). The picks below favour fast,
single-binary, mostly Rust/Go tools over the older Node/Python-runtime linters they
replace. Builtin names are the snake_case Pkl identifiers (`Builtins.ox_lint`).

Once the steps are chosen, see `pipeline.md` for the order to run them in.

## Always on

| Builtin                                                                              | Tool needed                       |
| ------------------------------------------------------------------------------------ | --------------------------------- |
| `check_conventional_commit` (in `commit-msg`)                                        | — (uses `hk util`, no extra tool) |
| `check_merge_conflict`, `trailing_whitespace`, `newlines`, `check_added_large_files` | — (built into hk)                 |
| `gitleaks`, `detect_private_key`                                                     | `gitleaks`                        |
| `typos` — spell check across all text; replaces codespell/cspell                     | `typos`                           |

## By evidence in the repo

| Evidence in repo                     | Modern step(s)                                  | Replaces                             | mise tool                        |
| ------------------------------------ | ----------------------------------------------- | ------------------------------------ | -------------------------------- |
| `*.ts`/`*.js`, `package.json`        | `ox_lint`, `oxfmt`                              | `eslint`, `prettier`                 | `oxlint`, `npm:oxfmt`            |
| `tsconfig.json`                      | `tsc`                                           | —                                    | project-local via `package.json` |
| pnpm/npm workspaces monorepo         | `sherif`, optionally `knip`                     | —                                    | `npm:sherif`, `npm:knip`         |
| `*.py`, `pyproject.toml`             | `ruff`, `ruff_format`                           | `black`, `flake8`, `isort`, `pylint` | `ruff`                           |
| Python with type annotations         | `ty`                                            | `mypy`                               | `ty`                             |
| `*.md`                               | `rumdl`, `rumdl_format`                         | `markdown_lint` (markdownlint-cli2)  | `rumdl`                          |
| `*.yaml`/`*.yml` (beyond a couple)   | `ryl`                                           | `yamllint`                           | `cargo:ryl`                      |
| YAML embedded in markdown            | `ryl_markdown`                                  | —                                    | `cargo:ryl`                      |
| `*.toml`                             | `tombi`, `tombi_format`                         | `taplo`, `taplo_format`              | `tombi`                          |
| `Cargo.toml`                         | `cargo_fmt`, `cargo_clippy`                     | —                                    | — (rustup toolchain)             |
| `go.mod`                             | `golangci_lint`, `go_fumpt`                     | `go_fmt`, `go_vet`, `staticcheck`    | `golangci-lint`, `gofumpt`       |
| `*.sh`, shebang scripts              | `shellcheck`, `shfmt`                           | —                                    | `shellcheck`, `shfmt`            |
| `.github/workflows/`                 | `jactionlint` custom step, optional `pinact`    | `actionlint`, `zizmor`               | `jactionlint`, optional `pinact` |
| `Dockerfile*`                        | `hadolint`                                      | —                                    | `hadolint`                       |
| `docker-compose.y*ml`                | `dclint`                                        | —                                    | `npm:dclint`                     |
| `*.tf`                               | `tofu` (or `terraform`), `tf_lint`              | —                                    | `opentofu`/`terraform`, `tflint` |
| `*.tf` with `terraform-docs` READMEs | `terraform_docs`, `terraform_validate`          | —                                    | `terraform-docs`, `terraform`    |
| `terragrunt.hcl`                     | `terragrunt_hcl_fmt`, `terragrunt_hcl_validate` | —                                    | `terragrunt` (1.0.8+)            |
| Kubernetes manifests                 | `kubeconform`, `kube_linter`                    | —                                    | `kubeconform`, `kube-linter`     |
| `*.lua`                              | `stylua`, `selene`                              | `luacheck`                           | `stylua`, `cargo:selene`         |
| `*.nix`                              | `nix_fmt` (or `alejandra`), `deadnix`           | —                                    | — / `alejandra`, `deadnix`       |
| `*.pkl` (e.g. `hk.pkl` itself)       | `pkl`, `pkl_format`                             | —                                    | `pkl`                            |
| `mise.toml`                          | `mise` (`mise fmt`)                             | —                                    | — (mise is already required)     |
| OpenAPI spec files                   | `vacuum`                                        | `spectral`                           | `vacuum`                         |
| Docs-heavy repo, prose matters       | `harper`                                        | `vale`, `textlint`                   | `harper-cli` (source install)    |
| Many external links in docs          | `lychee`                                        | —                                    | `lychee`                         |

## Legacy → modern at a glance

| Legacy builtin                                 | Modern replacement       | Why                                                    |
| ---------------------------------------------- | ------------------------ | ------------------------------------------------------ |
| `eslint`                                       | `ox_lint`                | Rust, ~50-100x faster, no node_modules resolution cost |
| `prettier`                                     | `oxfmt`                  | Prettier-compatible output, Rust, single binary        |
| `black`, `flake8`, `isort`, `pylint`           | `ruff` + `ruff_format`   | One tool covers lint + format + import sort            |
| `mypy`                                         | `ty`                     | Rust, incremental, far faster (still pre-1.0)          |
| `markdown_lint`                                | `rumdl` + `rumdl_format` | Rust, no Node runtime; same rule IDs as markdownlint   |
| `yamllint`                                     | `ryl`                    | Rust re-implementation, reads `.yamllint` config       |
| `taplo`, `taplo_format`                        | `tombi`, `tombi_format`  | Schema-aware TOML lint + format                        |
| `go_fmt`, `go_vet`, `staticcheck`, `err_check` | `golangci_lint`          | One meta-linter run instead of N processes             |
| `go_fmt`                                       | `go_fumpt`               | Stricter superset of gofmt                             |
| `luacheck`                                     | `selene`                 | Rust, better diagnostics                               |
| `vale`, `textlint`                             | `harper`                 | Rust, no config or style-package setup                 |
| codespell / cspell (external)                  | `typos`                  | Rust, near-zero false positives, autofix               |

## Notes on specific picks

- **`ox_lint` / `oxfmt`** — oxfmt is Prettier-compatible and orders of magnitude faster.
  If the repo already has `biome.json`, keep `biome` instead; it covers both roles.
  If the repo uses vite-plus, `vp_check` / `vp_fmt` / `vp_lint` wrap the same oxc engine
  behind the `vp` CLI.
- **`ty`** is Astral's type checker and is still pre-1.0. Offer it, but fall back to
  `mypy` if the repo has existing mypy config or the check turns out too noisy.
- **`rumdl`** ships a linter (`rumdl check`) and a formatter (`rumdl fmt`) as two
  separate builtins. Include both for docs repos, just `rumdl_format` if you only want
  formatting and no rule enforcement.
- **`betterleaks`** is a faster, more configurable gitleaks alternative that reads
  `.gitleaks.toml`. A reasonable swap, but `gitleaks` stays the default — wider adoption
  and a longer track record.
- **[`jactionlint` 2.2.0](https://github.com/jdx/jactionlint/releases/tag/v2.2.0)**
  checks GitHub Actions correctness and security, including the checks in
  `actionlint` and the audits in `zizmor`. Use a custom `Step` with hk 2.5.0;
  that release has no `Builtins.jactionlint`. Its `--fix` option can change
  workflow files, so place it with the content fixers. If a YAML formatter
  shares those files, make it depend on the `jactionlint` step. See
  `pipeline.md` for the step.
  **`pinact`** pins actions to commit SHAs and can update them (`pinact_update`).
- **`knip`** (unused files/deps/exports) and **`sherif`** (monorepo package.json hygiene)
  are useful but opinionated — they frequently fail on first run in an existing repo.
  Suggest them, don't add them silently.

## Avoid overlapping formatters

`oxfmt`'s default glob covers markdown, YAML, TOML, JSON, CSS, HTML and GraphQL in
addition to JS/TS. Exactly one formatter must own each file type, or the two will fight
on every commit. When combining, narrow `oxfmt` to the types nothing else claims:

```pkl
["oxfmt"] = (Builtins.oxfmt) {
    glob = List("**/*.js", "**/*.mjs", "**/*.cjs", "**/*.ts", "**/*.mts", "**/*.cts",
                "**/*.jsx", "**/*.tsx", "**/*.json", "**/*.jsonc", "**/*.css", "**/*.html")
}
```

Ownership precedence when both are selected: `rumdl_format` > oxfmt for markdown,
`tombi_format` > oxfmt for TOML, `ryl` / `yamlfmt` > oxfmt for YAML.

In a repo with **no** JS/TS at all, the inverse is fine — a single `oxfmt` step can cover
markdown/JSON/YAML without pulling in three more tools.

## mise install lines

Most of the subset is a plain registry name:

```toml
[tools]
oxlint = "latest"
rumdl = "latest"
tombi = "latest"
ty = "latest"
typos = "latest"
gitleaks = "latest"
pinact = "latest"
jactionlint = "2.2.0"
vacuum = "latest"
```

These are not in the mise registry and need an explicit backend:

```toml
[tools]
"npm:oxfmt" = "latest"
"cargo:ryl" = "latest"       # yamllint in Rust
"cargo:selene" = "latest"    # Lua linter
"npm:sherif" = "latest"      # JS monorepo linter
"npm:knip" = "latest"
"npm:dclint" = "latest"      # docker compose linter
```

`harper` needs the `harper-cli` binary, which is published to neither crates.io nor the
mise registry — it has to come from source
(`cargo install --git https://github.com/automattic/harper harper-cli`). Only add the
`harper` step if the user explicitly wants prose linting and accepts that install path.

Always verify a tool resolves before writing its step into `hk.pkl`:
`mise x -- <tool> --version`.
