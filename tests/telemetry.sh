#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-telemetry-test.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home" PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CODEX_HOME="$HOME/.codex" CODEX_INSTALL_DIR="$HOME/.local/bin"
export CLAUDE_CONFIG_DIR="$HOME/.claude"
export DOTFILES_APPLICATIONS_DIR="$fixture/apps"
export DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks"
export CALLS="$fixture/calls"
# The GUI job merges launchd's CRS properties only, never the caller's shell.
export AZ_CRS_ARGUMENTS='shell.only=1,enable=true'
mkdir -p "$fixture/bin" "$DOTFILES_APPLICATIONS_DIR" "$CODEX_HOME/packages/standalone/current/bin" "$HOME/.local/bin" "$HOME/.local/share/claude/versions/1" "$HOME/.claude"
printf '#!/bin/bash\nexit 0\n' > "$CODEX_HOME/packages/standalone/current/bin/codex"
cp "$CODEX_HOME/packages/standalone/current/bin/codex" "$HOME/.local/share/claude/versions/1/claude"
chmod +x "$CODEX_HOME/packages/standalone/current/bin/codex" "$HOME/.local/share/claude/versions/1/claude"
# Preserve unrelated CRS properties while replacing duplicate/bare enable.
printf 'api.url=https://example.test,enable=true,log=warning,enable' > "$HOME/launchd-crs"
[[ $(AZ_CRS_ARGUMENTS='a=1,enable,b=2,enable=true' /bin/sh -c '. "$1"; printf %s "$AZ_CRS_ARGUMENTS"' sh "$repo_root/home/.config/telemetry/env.sh") == 'a=1,b=2,enable=false' ]]
# The Claude settings values must match the shared environment.
/usr/bin/ruby -rjson -e 'JSON.parse(File.read(ARGV[0]))["env"].each { |k, v| File.read(ARGV[1]).include?("export #{k}=#{v}\n") or abort("#{k} differs") }' "$repo_root/home/.config/telemetry/claude.json" "$repo_root/home/.config/telemetry/env.sh"
ln -s "$CODEX_HOME/packages/standalone/current/bin/codex" "$HOME/.local/bin/codex"
ln -s "$HOME/.local/share/claude/versions/1/claude" "$HOME/.local/bin/claude"
for tool in brew vercel gcloud eas wrangler flyctl turbo; do
  cat > "$fixture/bin/$tool" <<'STUB'
#!/bin/bash
set -eu
[[ "$HOMEBREW_NO_ANALYTICS" == 1 && "$VERCEL_TELEMETRY_DISABLED" == 1 ]]
[[ "$DO_NOT_TRACK" == 1 && "$DISABLE_TELEMETRY" == 1 && "$DISABLE_ERROR_REPORTING" == 1 ]]
[[ "$WRANGLER_SEND_METRICS" == false && "$WRANGLER_SEND_ERROR_REPORTS" == false ]]
name="${0##*/}"
printf '%s %s\n' "$name" "$*" >> "$CALLS"
if [[ "$name" == "${HANG_TOOL:-}" ]]; then
  sleep 60 &
  echo "$!" > "$HOME/probe-child.pid"
  wait
fi
[[ "$name" != "${FAIL_TOOL:-}" ]]
STUB
  chmod +x "$fixture/bin/$tool"
done
cat > "$fixture/bin/launchctl" <<'STUB'
#!/bin/bash
set -eu
printf 'launchctl %s\n' "$*" >> "$CALLS"
case "$1" in
  print) [[ -f "$HOME/job-loaded" ]] ;;
  bootstrap)
    if [[ -f "$HOME/fail-bootstrap-once" ]]; then rm "$HOME/fail-bootstrap-once"; exit 1; fi
    [[ "${FAIL_LAUNCH:-0}" != 1 && ! -f "$HOME/job-loaded" ]] || exit 1; touch "$HOME/job-loaded" ;;
  bootout) [[ -f "$HOME/job-loaded" ]] || exit 3; rm "$HOME/job-loaded" ;;
  getenv) [[ "$2" == AZ_CRS_ARGUMENTS ]]; [[ ! -f "$HOME/launchd-crs" ]] || cat "$HOME/launchd-crs" ;;
  setenv)
    case "$2" in ''|*[!A-Z0-9_]*) exit 99 ;; esac
    if [[ "$2" == AZ_CRS_ARGUMENTS ]]; then
      if [[ -f "$HOME/launchd-crs" ]]; then
        [[ "$3" == 'api.url=https://example.test,log=warning,enable=false' ]]
      else
        [[ "$3" == enable=false ]]
      fi
    else
      case "$3" in 1|0|true|false|YES) ;; *) exit 99 ;; esac
    fi ;;
  unsetenv) [[ "$2" == DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT ]] ;;
  *) exit 99 ;;
esac
STUB
chmod +x "$fixture/bin/launchctl"
cat > "$CODEX_HOME/config.toml" <<'TOML'
model = "fixture-model"
notes = "literal triple quotes ''' and # hash"
other = 'literal double triple quotes """'
instructions = '''
[analytics]
enabled = true
'''
[analytics] # keep this comment
enabled = true # existing consent
[otel]
exporter = "otlp-http"
environment = "fixture-environment"
[projects."/fixture"]
trust_level = "trusted"
TOML
printf '{"keep":true,"env":{"OTHER":"keep","DISABLE_TELEMETRY":"0"}}\n' > "$HOME/.claude/settings.json"
cp "$CODEX_HOME/config.toml" "$fixture/codex-before"
cp "$HOME/.claude/settings.json" "$fixture/claude-before"
chmod 600 "$CODEX_HOME/config.toml"
# Dry-run plans changes without calling any setter or changing settings.
"$repo_root/bin/configure-telemetry" --dry-run > "$fixture/dry.log" 2>&1
[[ ! -e "$CALLS" ]]
cmp "$CODEX_HOME/config.toml" "$fixture/codex-before"
cmp "$HOME/.claude/settings.json" "$fixture/claude-before"
[[ ! -d "$HOME/.dotfiles-backups" ]]
[[ ! -e "$HOME/bin/dotfiles-telemetry-env" ]]
grep -q 'Would configure telemetry: wrangler telemetry disable' "$fixture/dry.log"
"$repo_root/bin/configure-telemetry" > "$fixture/run.log" 2>&1
grep -Fqx 'brew analytics off' "$CALLS"
grep -Fqx 'gcloud config set core/disable_usage_reporting true' "$CALLS"
grep -Fqx 'vercel telemetry disable' "$CALLS"
grep -Fqx 'eas analytics off' "$CALLS"
grep -Fqx 'wrangler telemetry disable' "$CALLS"
grep -Fqx 'flyctl settings analytics disable' "$CALLS"
grep -Fqx 'turbo telemetry disable' "$CALLS"
grep -Fqx 'launchctl setenv BINSTALL_DISABLE_TELEMETRY true' "$CALLS"
grep -Fqx 'launchctl setenv T3CODE_TELEMETRY_ENABLED false' "$CALLS"
grep -Fqx 'launchctl setenv AZ_CRS_ARGUMENTS api.url=https://example.test,log=warning,enable=false' "$CALLS"
grep -Fqx 'launchctl unsetenv DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT' "$CALLS"
! grep -q '^launchctl setenv PATH ' "$CALLS"
grep -Fqx 'enabled = false # existing consent' "$CODEX_HOME/config.toml"
grep -Fqx 'exporter = "none"' "$CODEX_HOME/config.toml"
grep -Fqx 'metrics_exporter = "none"' "$CODEX_HOME/config.toml"
grep -Fqx 'environment = "fixture-environment"' "$CODEX_HOME/config.toml"
grep -Fqx 'trust_level = "trusted"' "$CODEX_HOME/config.toml"
/usr/bin/ruby -rjson -e 's=JSON.parse(File.read(ARGV[0])); abort unless s["keep"] && s["env"]["OTHER"]=="keep" && s["env"]["DISABLE_TELEMETRY"]=="1" && s["env"]["DISABLE_ERROR_REPORTING"]=="1"' "$HOME/.claude/settings.json"
[[ $(stat -f %Lp "$CODEX_HOME/config.toml") == 600 ]]
count="$(find "$HOME/.dotfiles-backups" -type f | wc -l)"
[[ "$count" == 2 ]]
cp "$CODEX_HOME/config.toml" "$fixture/codex-after"
"$repo_root/bin/configure-telemetry" --agents-only >> "$fixture/run.log" 2>&1
cmp "$CODEX_HOME/config.toml" "$fixture/codex-after"
[[ $(find "$HOME/.dotfiles-backups" -type f | wc -l) == "$count" ]]
# A failed setter still permits other installed tools to be configured.
: > "$CALLS"
if FAIL_TOOL=vercel "$repo_root/bin/configure-telemetry" > "$fixture/failure.log" 2>&1; then exit 1; fi
grep -Fqx 'wrangler telemetry disable' "$CALLS"
grep -q 'Could not configure vercel telemetry' "$fixture/failure.log"
# Complex or malformed input must be preserved and reported, without backups.
printf 'analytics = { enabled = true }\n' > "$CODEX_HOME/config.toml"
cp "$CODEX_HOME/config.toml" "$fixture/complex-before"
if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/complex.log" 2>&1; then exit 1; fi
cmp "$CODEX_HOME/config.toml" "$fixture/complex-before"
printf '["otel"."exporter".otlp_http]\nendpoint = "https://example.test"\n' > "$CODEX_HOME/config.toml"
cp "$CODEX_HOME/config.toml" "$fixture/nested-before"
if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/nested.log" 2>&1; then exit 1; fi
cmp "$CODEX_HOME/config.toml" "$fixture/nested-before"
printf '[otel]\nexporter.otlp-http.endpoint = "https://example.test"\n' > "$CODEX_HOME/config.toml"
cp "$CODEX_HOME/config.toml" "$fixture/dotted-before"
if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/dotted.log" 2>&1; then exit 1; fi
grep -q 'otel.exporter uses dotted keys' "$fixture/dotted.log"
cmp "$CODEX_HOME/config.toml" "$fixture/dotted-before"
cat > "$fixture/escaped-table" <<'TOML'
["anal\u0079tics"]
enabled = true
TOML
cat > "$fixture/escaped-key" <<'TOML'
[analytics]
"enabl\u0065d" = true
TOML
for escaped in "$fixture/escaped-table" "$fixture/escaped-key"; do
  cp "$escaped" "$CODEX_HOME/config.toml"
  cp "$CODEX_HOME/config.toml" "$fixture/escaped-before"
  if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/escaped.log" 2>&1; then exit 1; fi
  grep -q 'Escaped TOML' "$fixture/escaped.log"
  cmp "$CODEX_HOME/config.toml" "$fixture/escaped-before"
done
printf '[profiles.work]\nname = "unterminated\n' > "$CODEX_HOME/config.toml"
cp "$CODEX_HOME/config.toml" "$fixture/unterminated-before"
if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/unterminated.log" 2>&1; then exit 1; fi
grep -q 'Unterminated TOML string' "$fixture/unterminated.log"
cmp "$CODEX_HOME/config.toml" "$fixture/unterminated-before"
# Nested array values must not be read as table headers or hide managed keys.
cat > "$CODEX_HOME/config.toml" <<'TOML'
[analytics]
metadata = [
  [1, 2],
  ["[otel]", "quoted bracket ]"],
  ["""same line"""],
  '''
[otel]
exporter = "keep this literal"
''',
]
enabled = true
TOML
"$repo_root/bin/configure-telemetry" --agents-only > "$fixture/array.log" 2>&1
[[ $(grep -c '^enabled = ' "$CODEX_HOME/config.toml") == 1 ]]
grep -Fqx 'enabled = false' "$CODEX_HOME/config.toml"
grep -Fqx 'exporter = "keep this literal"' "$CODEX_HOME/config.toml"
count="$(find "$HOME/.dotfiles-backups" -type f | wc -l)"
printf '{broken synthetic-private-telemetry-value\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$fixture/broken-before"
if "$repo_root/bin/configure-telemetry" --agents-only > "$fixture/broken.log" 2>&1; then exit 1; fi
cmp "$HOME/.claude/settings.json" "$fixture/broken-before"
! grep -q synthetic-private-telemetry-value "$fixture/broken.log"
[[ $(find "$HOME/.dotfiles-backups" -type f | wc -l) == "$count" ]]
# A header without a newline must remain valid when adding missing keys.
printf '[analytics]' > "$CODEX_HOME/config.toml"
printf '{}' > "$HOME/.claude/settings.json"
"$repo_root/bin/configure-telemetry" --agents-only > "$fixture/newline.log" 2>&1
grep -Fqx '[analytics]' "$CODEX_HOME/config.toml"
grep -Fqx 'enabled = false' "$CODEX_HOME/config.toml"
# Resolve existing links and retain them when merging local settings.
mv "$HOME/.claude/settings.json" "$fixture/settings.json"
ln -s "$fixture/settings.json" "$HOME/.claude/settings.json"
"$repo_root/bin/configure-telemetry" --agents-only > "$fixture/link.log" 2>&1
[[ -L "$HOME/.claude/settings.json" ]]
# The desktop app also uses the shared runtime when the CLI is absent.
chmod -x "$CODEX_HOME/packages/standalone/current/bin/codex"
mkdir -p "$DOTFILES_APPLICATIONS_DIR/ChatGPT.app"
printf '[analytics]\nenabled = true\n' > "$CODEX_HOME/config.toml"
"$repo_root/bin/configure-telemetry" --agents-only > "$fixture/desktop-runtime.log" 2>&1
grep -Fqx 'enabled = false' "$CODEX_HOME/config.toml"
chmod +x "$CODEX_HOME/packages/standalone/current/bin/codex"
# App settings retain JSONC comments, nested state, and runtime identity.
mkdir -p "$DOTFILES_APPLICATIONS_DIR/Cursor.app" "$DOTFILES_APPLICATIONS_DIR/T3 Code (Nightly).app" "$HOME/Library/Application Support/Cursor/User" "$HOME/.cursor"
cat > "$HOME/Library/Application Support/Cursor/User/settings.json" <<'JSONC'
{
  // keep this user comment
  "url": "https://example.test/a//b",
  "keep": { "array": ["/* literal */",], },
  "telemetry.telemetryLevel": "all", // preserve this comment
}
JSONC
printf '{\n  "crash-reporter-id": "fixture-id", // keep identity\n}\n' > "$HOME/.cursor/argv.json"
"$repo_root/bin/configure-telemetry" > "$fixture/apps.log" 2>&1
grep -Fq '// keep this user comment' "$HOME/Library/Application Support/Cursor/User/settings.json"
grep -Fq '"url": "https://example.test/a//b"' "$HOME/Library/Application Support/Cursor/User/settings.json"
grep -Fq '"keep": { "array": ["/* literal */",], }' "$HOME/Library/Application Support/Cursor/User/settings.json"
grep -Fq '"telemetry.telemetryLevel": "off", // preserve this comment' "$HOME/Library/Application Support/Cursor/User/settings.json"
grep -Fq '"crash-reporter-id": "fixture-id", // keep identity' "$HOME/.cursor/argv.json"
grep -Fq '"enable-crash-reporter": false' "$HOME/.cursor/argv.json"
plist="$HOME/Library/LaunchAgents/com.dotfiles.telemetry-env.plist"
[[ -L "$HOME/.config/telemetry/env.sh" && -L "$HOME/bin/dotfiles-telemetry-env" && -f "$plist" && ! -L "$plist" ]]
cp "$HOME/Library/Application Support/Cursor/User/settings.json" "$fixture/cursor-after"
"$repo_root/bin/configure-telemetry" >> "$fixture/apps.log" 2>&1
cmp "$HOME/Library/Application Support/Cursor/User/settings.json" "$fixture/cursor-after"
[[ $(grep -c '^launchctl bootstrap ' "$CALLS") == 1 ]]
# Check the login-job script with a fake launchctl, never the live GUI session.
/usr/bin/python3 - "$HOME/Library/LaunchAgents/com.dotfiles.telemetry-env.plist" "$fixture/bin/launchctl" <<'PY'
import plistlib,subprocess,sys
with open(sys.argv[1],'rb') as file: config=plistlib.load(file)
assert config['RunAtLoad'] and 'KeepAlive' not in config
args=config['ProgramArguments']
subprocess.run(args,check=True)
PY
# A login without launchd CRS properties sets only enable=false.
rm "$HOME/launchd-crs"
: > "$CALLS"
"$HOME/bin/dotfiles-telemetry-env"
grep -Fqx 'launchctl setenv AZ_CRS_ARGUMENTS enable=false' "$CALLS"
# A changed installed plist is backed up, replaced, and reloaded.
printf '<!-- local change -->\n' >> "$plist"
: > "$CALLS"
"$repo_root/bin/configure-telemetry" >> "$fixture/apps.log" 2>&1
cmp "$plist" "$repo_root/home/Library/LaunchAgents/com.dotfiles.telemetry-env.plist"
grep -rqF -- '<!-- local change -->' "$HOME/.dotfiles-backups"
[[ $(grep -c '^launchctl bootout ' "$CALLS") == 1 && $(grep -c '^launchctl bootstrap ' "$CALLS") == 1 ]]
# An unchanged loaded job is not reloaded.
: > "$CALLS"
"$repo_root/bin/configure-telemetry" >> "$fixture/apps.log" 2>&1
! grep -q '^launchctl boot' "$CALLS"
# An earlier link to the tracked plist is replaced without a backup, and a
# bootstrap that fails right after bootout is retried once.
rm "$plist"
ln -s "$repo_root/home/Library/LaunchAgents/com.dotfiles.telemetry-env.plist" "$plist"
count="$(find "$HOME/.dotfiles-backups" -type f | wc -l)"
touch "$HOME/fail-bootstrap-once"
: > "$CALLS"
"$repo_root/bin/configure-telemetry" >> "$fixture/apps.log" 2>&1
[[ -f "$plist" && ! -L "$plist" ]]
[[ $(find "$HOME/.dotfiles-backups" -type f | wc -l) == "$count" ]]
[[ $(grep -c '^launchctl bootstrap ' "$CALLS") == 2 && -f "$HOME/job-loaded" ]]
rm "$HOME/job-loaded"
if FAIL_LAUNCH=1 "$repo_root/bin/configure-telemetry" > "$fixture/job-fail.log" 2>&1; then exit 1; fi
grep -q 'Could not load the telemetry environment login job' "$fixture/job-fail.log"
# Bound a hung command and stop its child while unrelated setters continue.
: > "$CALLS"
if HANG_TOOL=vercel DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS=1 "$repo_root/bin/configure-telemetry" > "$fixture/timeout.log" 2>&1; then exit 1; fi
grep -Fqx 'wrangler telemetry disable' "$CALLS"
child="$(cat "$HOME/probe-child.pid")"
! kill -0 "$child" 2>/dev/null
printf 'PASS: telemetry environment, supported setters, dry-run, preserved settings/backups, idempotence, failure isolation, malformed input, links, GUI login job, JSONC comments, bounded commands\n'
