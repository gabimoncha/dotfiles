#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/home" "$fixture/bin" "$fixture/brew/etc" "$fixture/apps"
export DOTFILES_APPLICATIONS_DIR="$fixture/apps"
export HOME="$fixture/home" PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks" FIXTURE_BREW="$fixture/brew"
printf '#!/bin/bash\nprintf "%%s\\n" "$FIXTURE_BREW"\n' > "$fixture/bin/brew"
chmod +x "$fixture/bin/brew"
printf 'existing shell fixture\n' > "$HOME/.zshrc"
mkdir -p "$HOME/.claude"
printf 'existing Claude instructions fixture\n' > "$HOME/.claude/CLAUDE.md"
printf '{"keep":true,"env":{"LOCAL_KEEP":"fixture"}}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$fixture/settings-before"
printf 'existing service fixture\n' > "$fixture/brew/etc/cliproxyapi.conf"
"$repo_root/bin/link-dotfiles" --telemetry-only >/dev/null
[[ ! -L "$HOME/.zshrc" && ! -L "$HOME/.claude/CLAUDE.md" && ! -L "$fixture/brew/etc/cliproxyapi.conf" ]]
[[ -L "$HOME/.config/telemetry/env.sh" && -L "$HOME/bin/dotfiles-telemetry-env" ]]
# The login job plist is a copy, so configure-telemetry can detect changes.
plist="$HOME/Library/LaunchAgents/com.dotfiles.telemetry-env.plist"
[[ -f "$plist" && ! -L "$plist" ]]
cmp "$plist" "$repo_root/home/Library/LaunchAgents/com.dotfiles.telemetry-env.plist"
cmp "$HOME/.claude/settings.json" "$fixture/settings-before"
"$repo_root/bin/link-dotfiles" >/dev/null
[[ -L "$HOME/.zshrc" && -L "$HOME/bin/dotfiles-gh-real" ]]
[[ -L "$HOME/bin/harness" ]]
[[ -L "$HOME/.config/zsh/harness.zsh" ]]
[[ -L "$HOME/.config/telemetry/env.sh" ]]
"$HOME/bin/harness" --help | grep -q 'harness update'
[[ -L "$HOME/.codex/AGENTS.md" ]]
[[ -L "$HOME/.claude/CLAUDE.md" ]]
[[ "$(readlink "$HOME/.codex/AGENTS.md")" == "$repo_root/home/.codex/AGENTS.md" ]]
[[ "$(readlink "$HOME/.claude/CLAUDE.md")" == "$repo_root/home/.codex/AGENTS.md" ]]
grep -Fqx "If you're working on coding tasks, use Simplified Technical English, defined by the ASD-STE100 standard, when replying back to the user." "$HOME/.codex/AGENTS.md"
grep -Fqx "If you're working on coding tasks, use Simplified Technical English, defined by the ASD-STE100 standard, when replying back to the user." "$HOME/.claude/CLAUDE.md"
[[ -L "$fixture/brew/etc/cliproxyapi.conf" ]]
/usr/bin/ruby -rjson -e 's=JSON.parse(File.read(ARGV[0])); abort unless s["keep"] && s["env"]=={"LOCAL_KEEP"=>"fixture"} && s["pluginConfigs"].is_a?(Hash)' "$HOME/.claude/settings.json"
backup="$(find "$HOME/.dotfiles-backups" -name .zshrc -type f)"
[[ "$(cat "$backup")" == 'existing shell fixture' ]]
claude_backup="$(find "$HOME/.dotfiles-backups" -path '*/.claude/CLAUDE.md' -type f)"
[[ "$(cat "$claude_backup")" == 'existing Claude instructions fixture' ]]
count="$(find "$HOME/.dotfiles-backups" -type f | wc -l)"
"$repo_root/bin/link-dotfiles" >/dev/null
[[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l)" == "$count" ]]
[[ "$(cat "$backup")" == 'existing shell fixture' ]]
# Refuse an invalid env schema and malformed content before any write.
printf '{"pluginConfigs":"keep-invalid-fixture"}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$fixture/invalid-before"
if bash "$repo_root/bin/configure-claude-settings" > "$fixture/invalid.log" 2>&1; then exit 1; fi
cmp "$HOME/.claude/settings.json" "$fixture/invalid-before"
grep -q 'Claude setting pluginConfigs must be a JSON object' "$fixture/invalid.log"
printf '{broken synthetic-private-clause\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$fixture/invalid-before"
if bash "$repo_root/bin/configure-claude-settings" > "$fixture/invalid.log" 2>&1; then exit 1; fi
cmp "$HOME/.claude/settings.json" "$fixture/invalid-before"
grep -q 'Invalid Claude settings JSON' "$fixture/invalid.log"
! grep -q synthetic-private-clause "$fixture/invalid.log"
[[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l)" == "$count" ]]
printf 'PASS: idempotent linking, shared Codex and Claude instructions, existing-file backups, direct credential helper link, service configuration\n'
