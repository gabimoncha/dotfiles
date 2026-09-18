#!/usr/bin/env bash
set -euo pipefail
source_repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo/bin/lib" "$fixture/repo/apps" "$fixture/home/.local/bin" "$fixture/fakebin"
cp "$source_repo/bin/bootstrap" "$fixture/repo/bin/bootstrap"
printf '#!/usr/bin/env bash\nprintf "check\\n" >> "$CALLS"\nexit 9\n' > "$fixture/repo/bin/check-mise-tools"
chmod +x "$fixture/repo/bin/check-mise-tools"
printf 'runtime_with_lock() { shift; "$@"; }\nruntime_init() { :; }\n' > "$fixture/repo/bin/lib/setup-runtime.sh"
cat > "$fixture/home/.local/bin/mise" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALLS"
case "$1" in install) exit 7;; *) exit 0;; esac
STUB
chmod +x "$fixture/home/.local/bin/mise"
export HOME="$fixture/home" CALLS="$fixture/calls"
: > "$CALLS"
DOTFILES_BOOTSTRAP_LIBRARY=1 . "$fixture/repo/bin/bootstrap"
status=0
install_and_check_mise_tools || status=$?
[[ "$status" -eq 7 ]]
[[ "$(cat "$CALLS")" == $'install\nreshim\ncheck' ]]
printf 'PASS partial mise refreshes and checks while preserving status\n'
cp "$source_repo/bin/install-apps" "$fixture/repo/bin/install-apps"
# Remove host discovery in the copied fixture; no host package manager can execute.
python3 - "$fixture/repo/bin/install-apps" <<'PY'
import sys
p=sys.argv[1];s=open(p).read();a=s.index('load_homebrew_shellenv() {');b=s.index('\nprepend_mise_shims()',a);s=s[:a]+'load_homebrew_shellenv() { :; }\n'+s[b:];open(p,'w').write(s)
PY
printf 'one\tformula\tfirst\t-\t-\ntwo\tformula\tsecond\t-\t-\n' > "$fixture/repo/apps/manifest.tsv"
cat > "$fixture/fakebin/brew" <<'STUB'
#!/usr/bin/env bash
case "$1" in list) exit 1;; install) printf '%s\n' "$2" >> "$CALLS"; [[ "$2" != first ]];; esac
STUB
chmod +x "$fixture/fakebin/brew"
: > "$CALLS"
status=0
PATH="$fixture/fakebin:/usr/bin:/bin" bash "$fixture/repo/bin/install-apps" > "$fixture/apps.log" 2>&1 || status=$?
[[ "$status" -eq 1 && "$(cat "$CALLS")" == $'first\nsecond' ]]
printf 'PASS failed manifest entry does not stop unrelated apps\n'
: > "$CALLS"
PATH="$fixture/fakebin:/usr/bin:/bin" bash "$fixture/repo/bin/install-apps" --dry-run > "$fixture/apps-dry.log" 2>&1
[[ ! -s "$CALLS" ]]
grep -q 'dry-run: would install formula' "$fixture/apps-dry.log"
printf 'PASS manifest dry-run performs no package writes\n'

status=0
PATH="/usr/bin:/bin" bash "$fixture/repo/bin/install-apps" > "$fixture/absent.log" 2>&1 || status=$?
[[ "$status" -eq 1 ]]
printf 'PASS absent Homebrew fails the app pass\n'
cp "$source_repo/bin/ensure-mise-standalone" "$fixture/repo/bin/ensure-mise-standalone"
python3 - "$fixture/repo/bin/ensure-mise-standalone" <<'PY'
import sys
p=sys.argv[1];s=open(p).read();a=s.index('load_homebrew_shellenv() {');b=s.index('\nstandalone_mise_ok()',a);s=s[:a]+'load_homebrew_shellenv() { :; }\n'+s[b:];open(p,'w').write(s)
PY
: > "$CALLS"
PATH="/usr/bin:/bin" bash "$fixture/repo/bin/ensure-mise-standalone" > "$fixture/mise.log" 2>&1
! grep -q 'self-update --yes' "$CALLS"
printf 'PASS healthy mise rerun does not upgrade\n'
cp "$source_repo/bin/check-mise-tools" "$fixture/repo/bin/check-mise-tools"
python3 - "$fixture/repo/bin/check-mise-tools" <<'PY'
import sys
p=sys.argv[1];s=open(p).read();a=s.index('load_homebrew_shellenv() {');b=s.index('\nload_homebrew_shellenv\n',a);s=s[:a]+'load_homebrew_shellenv() { :; }\n'+s[b:];open(p,'w').write(s)
PY
mkdir -p "$fixture/home/.local/share/mise/shims" "$fixture/real"
printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture/real/tool"
cp "$fixture/real/tool" "$fixture/home/.local/share/mise/shims/tool"
chmod +x "$fixture/real/tool" "$fixture/home/.local/share/mise/shims/tool"
cat > "$fixture/home/.local/bin/mise" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  ls) exit 0;;
  which) printf '%s\n' "$RESOLVED_TOOL";;
  *) exit 99;;
esac
STUB
status=0
RESOLVED_TOOL="$fixture/home/.local/share/mise/shims/tool" PATH="/usr/bin:/bin" bash "$fixture/repo/bin/check-mise-tools" > "$fixture/check-shims.log" 2>&1 || status=$?
[[ "$status" -eq 1 ]]
RESOLVED_TOOL="$fixture/real/tool" PATH="/usr/bin:/bin" bash "$fixture/repo/bin/check-mise-tools" > "$fixture/check-real.log" 2>&1
printf 'PASS validation rejects shims and executes real tools\n'
# Model the observed Corepack fallback and a hung tool/version resolver.
mkdir -p "$fixture/real/corepack/dist"
printf '#!/bin/bash\ntouch "$COREPACK_EXECUTED"\nexit 99\n' > "$fixture/real/corepack/dist/pnpm.js"
chmod +x "$fixture/real/corepack/dist/pnpm.js"
ln -s corepack/dist/pnpm.js "$fixture/real/pnpm"
cat > "$fixture/real/hang" <<'STUB'
#!/bin/bash
trap '' TERM
sleep 300 &
echo "$!" > "$PROBE_CHILD"
wait
STUB
chmod +x "$fixture/real/hang"
cat > "$fixture/home/.local/bin/mise" <<'STUB'
#!/bin/bash
[[ "$MISE_AUTO_INSTALL" == 0 && "$MISE_OFFLINE" == 1 ]]
[[ "$COREPACK_ENABLE_NETWORK" == 0 && "$COREPACK_ENABLE_DOWNLOAD_PROMPT" == 0 ]]
case "$1" in
  ls) exit 0 ;;
  which)
    if [[ "$2" == pnpm ]]; then
      case "$PROBE_CASE" in
        corepack) printf '%s/pnpm\n' "$PROBE_ROOT" ;;
        version) printf '%s/hang\n' "$PROBE_ROOT" ;;
        resolver) exec "$PROBE_ROOT/hang" ;;
      esac
    else printf '%s/tool\n' "$PROBE_ROOT"; fi ;;
  *) exit 99 ;;
esac
STUB
export PROBE_ROOT="$fixture/real" PROBE_CHILD="$fixture/probe-child" COREPACK_EXECUTED="$fixture/corepack-executed"
for probe_case in corepack version resolver; do
  started=$SECONDS
  status=0
  PROBE_CASE="$probe_case" DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS=1 PATH="/usr/bin:/bin" bash "$fixture/repo/bin/check-mise-tools" > "$fixture/check-$probe_case.log" 2>&1 || status=$?
  [[ "$status" == 1 && $((SECONDS-started)) -lt 10 ]]
  grep -q 'Checking vercel' "$fixture/check-$probe_case.log"
  [[ ! -e "$COREPACK_EXECUTED" ]]
  if [[ "$probe_case" != corepack ]]; then
    child="$(cat "$PROBE_CHILD")"
    ! kill -0 "$child" 2>/dev/null
  fi
done
grep -q 'resolves to Corepack' "$fixture/check-corepack.log"
grep -q 'Version check timed out after 1s: pnpm' "$fixture/check-version.log"
grep -q 'Installed executable unavailable: pnpm' "$fixture/check-resolver.log"
printf 'PASS Corepack fallback rejected; hung probes bounded, descendants stopped, subsequent checks continue\n'
# A corrupt downloaded installer must never execute. Only a fake curl is used.
cp "$source_repo/bin/ensure-mise-standalone" "$fixture/repo/bin/ensure-mise-standalone"
cat > "$fixture/fakebin/curl" <<'STUB'
#!/usr/bin/env bash
while [[ $# -gt 0 ]]; do
  if [[ "$1" == -o ]]; then
    printf '#!/bin/sh\ntouch "$INSTALLER_EXECUTED"\n' > "$2"
    exit 0
  fi
  shift
done
exit 1
STUB
chmod +x "$fixture/fakebin/curl"
status=0
INSTALLER_EXECUTED="$fixture/installer-executed" MISE_INSTALL_PATH="$fixture/missing/mise" PATH="$fixture/fakebin:/usr/bin:/bin" bash "$fixture/repo/bin/ensure-mise-standalone" > "$fixture/checksum.log" 2>&1 || status=$?
[[ "$status" -ne 0 && ! -e "$fixture/installer-executed" ]]
grep -q 'checksum mismatch' "$fixture/checksum.log"
printf 'PASS installer checksum mismatch prevents execution\n'
