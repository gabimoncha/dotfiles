#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/home" "$fixture/bin" "$fixture/brew/etc" "$fixture/apps"
export DOTFILES_APPLICATIONS_DIR="$fixture/apps"
export HOME="$fixture/home" PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CODEX_HOME="$HOME/.codex"
export DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks" FIXTURE_BREW="$fixture/brew"
printf '#!/bin/bash\nprintf "%%s\\n" "$FIXTURE_BREW"\n' > "$fixture/bin/brew"
chmod +x "$fixture/bin/brew"
printf 'existing shell fixture\n' > "$HOME/.zshrc"
mkdir -p "$HOME/.claude" "$HOME/.codex"
cat > "$HOME/.codex/config.toml" <<'TOML'
model = "fixture-model"
[features]
memories = true # existing preference
multi_agent = true
[profiles.work]
model = "fixture-work-model"
TOML
cp "$HOME/.codex/config.toml" "$fixture/codex-before"
chmod 600 "$HOME/.codex/config.toml"
bash "$repo_root/bin/configure-codex-settings" --dry-run > "$fixture/codex-dry-run.log"
cmp "$HOME/.codex/config.toml" "$fixture/codex-before"
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
cmp "$HOME/.codex/config.toml" "$fixture/codex-before"
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
/usr/bin/ruby -rjson -e 's=JSON.parse(File.read(ARGV[0])); abort unless s["keep"] && s["env"]=={"LOCAL_KEEP"=>"fixture", "CLAUDE_CODE_DISABLE_AUTO_MEMORY"=>"1"} && s["pluginConfigs"].is_a?(Hash)' "$HOME/.claude/settings.json"
grep -Fqx 'memories = false # existing preference' "$HOME/.codex/config.toml"
grep -Fqx 'multi_agent = true' "$HOME/.codex/config.toml"
grep -Fqx 'model = "fixture-work-model"' "$HOME/.codex/config.toml"
[[ $(stat -f %Lp "$HOME/.codex/config.toml") == 600 ]]
codex_backup="$(find "$HOME/.dotfiles-backups" -path '*/.codex/config.toml' -type f)"
cmp "$codex_backup" "$fixture/codex-before"
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
printf '{"env":"keep-invalid-fixture"}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$fixture/invalid-before"
if bash "$repo_root/bin/configure-claude-settings" > "$fixture/invalid.log" 2>&1; then exit 1; fi
cmp "$HOME/.claude/settings.json" "$fixture/invalid-before"
grep -q 'Claude setting env must be a JSON object' "$fixture/invalid.log"
for content in 'features = { memories = true }' '[features.memories]' 'features.memories = true' '[features]\nmemories = [true]' '[features]\nmemories = true\nmemories = false' '[profiles.work]\nmodel = "unterminated'; do
  printf '%b\n' "$content" > "$HOME/.codex/config.toml"
  cp "$HOME/.codex/config.toml" "$fixture/codex-invalid-before"
  if bash "$repo_root/bin/configure-codex-settings" > "$fixture/codex-invalid.log" 2>&1; then exit 1; fi
  cmp "$HOME/.codex/config.toml" "$fixture/codex-invalid-before"
done
[[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l)" == "$count" ]]
mkdir -p "$fixture/custom-codex"
CODEX_HOME="$fixture/custom-codex" bash "$repo_root/bin/configure-codex-settings" >/dev/null
grep -Fqx '[features]' "$fixture/custom-codex/config.toml"
grep -Fqx 'memories = false' "$fixture/custom-codex/config.toml"
mv "$fixture/custom-codex/config.toml" "$fixture/codex-target.toml"
ln -s "$fixture/codex-target.toml" "$fixture/custom-codex/config.toml"
CODEX_HOME="$fixture/custom-codex" bash "$repo_root/bin/configure-codex-settings" >/dev/null
[[ -L "$fixture/custom-codex/config.toml" ]]
[[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l)" == "$count" ]]
printf 'PASS: idempotent linking, shared Codex and Claude instructions, existing-file backups, direct credential helper link, service configuration\n'
