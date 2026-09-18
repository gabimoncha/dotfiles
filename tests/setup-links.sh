#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/home" "$fixture/bin" "$fixture/brew/etc"
export HOME="$fixture/home" PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks" FIXTURE_BREW="$fixture/brew"
printf '#!/bin/bash\nprintf "%%s\\n" "$FIXTURE_BREW"\n' > "$fixture/bin/brew"
chmod +x "$fixture/bin/brew"
printf 'existing shell fixture\n' > "$HOME/.zshrc"
mkdir -p "$HOME/.claude"
printf 'existing Claude instructions fixture\n' > "$HOME/.claude/CLAUDE.md"
printf 'existing service fixture\n' > "$fixture/brew/etc/cliproxyapi.conf"
"$repo_root/bin/link-dotfiles" >/dev/null
[[ -L "$HOME/.zshrc" && -L "$HOME/bin/dotfiles-gh-real" ]]
[[ -L "$HOME/.codex/AGENTS.md" ]]
[[ -L "$HOME/.claude/CLAUDE.md" ]]
[[ "$(readlink "$HOME/.codex/AGENTS.md")" == "$repo_root/home/.codex/AGENTS.md" ]]
[[ "$(readlink "$HOME/.claude/CLAUDE.md")" == "$repo_root/home/.codex/AGENTS.md" ]]
grep -Fqx "If you're working on coding tasks, use Simplified Technical English, defined by the ASD-STE100 standard, when replying back to the user." "$HOME/.codex/AGENTS.md"
grep -Fqx "If you're working on coding tasks, use Simplified Technical English, defined by the ASD-STE100 standard, when replying back to the user." "$HOME/.claude/CLAUDE.md"
[[ -L "$fixture/brew/etc/cliproxyapi.conf" ]]
backup="$(find "$HOME/.dotfiles-backups" -name .zshrc -type f)"
[[ "$(cat "$backup")" == 'existing shell fixture' ]]
claude_backup="$(find "$HOME/.dotfiles-backups" -path '*/.claude/CLAUDE.md' -type f)"
[[ "$(cat "$claude_backup")" == 'existing Claude instructions fixture' ]]
count="$(find "$HOME/.dotfiles-backups" -type f | wc -l)"
"$repo_root/bin/link-dotfiles" >/dev/null
[[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l)" == "$count" ]]
[[ "$(cat "$backup")" == 'existing shell fixture' ]]
printf 'PASS: idempotent linking, shared Codex and Claude instructions, existing-file backups, direct credential helper link, service configuration\n'
