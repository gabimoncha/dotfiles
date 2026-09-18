#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-github-test.XXXXXX")"
trap 'status=$?; if [[ "$status" != 0 ]]; then cat "$fixture/acquire.log" 2>/dev/null || true; fi; rm -rf "$fixture"' EXIT
export DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks"
export HOME="$fixture/home" MISE_DATA_DIR="$fixture/data" MISE_CACHE_DIR="$fixture/cache" MISE_STATE_DIR="$fixture/state"
export PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
unset GH_TOKEN GITHUB_TOKEN MISE_GITHUB_TOKEN GITHUB_API_TOKEN GH_CONFIG_DIR
mkdir -p "$HOME/.local/bin" "$HOME/bin" "$fixture/bin" "$MISE_DATA_DIR"
cp "$repo_root/home/bin/dotfiles-gh-real" "$HOME/bin/"
cat > "$HOME/.local/bin/mise" <<'STUB'
#!/bin/bash
set -eu
case "$1" in
 install)
  [[ "$*" == 'install gh@2.100.0' ]]
  [[ "$HOME" == */dotfiles-gh.*/home ]]
  [[ "$MISE_CONFIG_DIR" == */dotfiles-gh.*/config ]]
  [[ "$MISE_SYSTEM_CONFIG_DIR" == */dotfiles-gh.*/system ]]
  [[ "$MISE_OVERRIDE_CONFIG_FILENAMES" == dotfiles-bootstrap-only.toml ]]
  [[ "$MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES" == none ]]
  [[ $(awk '/^gh =/{n++} END {print n+0}' "$MISE_GLOBAL_CONFIG_FILE") == 1 ]]
  ! /usr/bin/grep -q node "$MISE_GLOBAL_CONFIG_FILE"
  [[ ! -f "$MISE_DATA_DIR/fail-acquire" ]] || exit 22
  mkdir -p "$MISE_DATA_DIR/installs/gh/2.100.0/gh_2.100.0_macOS_arm64/bin"
  cp "$MISE_DATA_DIR/fake-gh" "$MISE_DATA_DIR/installs/gh/2.100.0/gh_2.100.0_macOS_arm64/bin/gh"
  printf 'install\n' >> "$MISE_DATA_DIR/calls"
  ;;
 token) "$HOME/bin/dotfiles-gh-real" auth token --hostname github.com ;;
 *) printf 'Forbidden mise call\n' >&2; exit 99 ;;
esac
STUB
cat > "$MISE_DATA_DIR/fake-gh" <<'STUB'
#!/bin/bash
set -eu
case "$1 $2" in
 '--version ') echo 'gh fixture' ;;
 'auth status') [[ ! -f "$MISE_DATA_DIR/fail-login" ]] ;;
 'auth token') printf 'synthetic-credential-do-not-log\n' ;;
 'api --hostname')
   case "$4" in
     user) [[ ! -f "$MISE_DATA_DIR/fail-api" ]] || { echo 'HTTP 403 synthetic-credential-do-not-log' >&2; exit 1; } ;;
     rate_limit)
       if [[ "${6:-}" == '.resources.core.reset' ]]; then echo 1234567890
       elif [[ -f "$MISE_DATA_DIR/quota-exhausted" ]]; then printf '0\t1234567890\n'
       else printf '100\t1234567890\n'; fi ;;
   esac ;;
 *) printf '%s\n' "$GH_TOKEN" ;;
esac
STUB
# --version has no second argument under nounset.
sed -i '' 's/"$1 $2"/"$1 ${2:-}"/' "$MISE_DATA_DIR/fake-gh"
chmod +x "$HOME/.local/bin/mise" "$MISE_DATA_DIR/fake-gh"
# If either PATH command is used, the fixture fails instead of reaching a real tool.
printf '#!/bin/bash\nexit 99\n' > "$fixture/bin/mise"
cp "$fixture/bin/mise" "$fixture/bin/gh"
chmod +x "$fixture/bin/"*
"$repo_root/bin/github-bootstrap" > "$fixture/acquire.log" 2>&1
"$repo_root/bin/github-bootstrap" >> "$fixture/acquire.log" 2>&1
[[ $(wc -l < "$MISE_DATA_DIR/calls" | tr -d ' ') == 1 ]]
[[ $("$HOME/bin/dotfiles-gh-real" --resolve) == */2.100.0/gh_2.100.0_macOS_arm64/bin/gh ]]
"$repo_root/bin/auth-setup" --api-only > "$fixture/api.log" 2>&1
"$repo_root/bin/auth-setup" --verify-mise > "$fixture/mise.log" 2>&1
# Authentication and API failures never cause a second install.
touch "$MISE_DATA_DIR/fail-login"
if "$repo_root/bin/auth-setup" --api-only >> "$fixture/api.log" 2>&1; then exit 1; fi
rm "$MISE_DATA_DIR/fail-login"
touch "$MISE_DATA_DIR/fail-api"
if "$repo_root/bin/auth-setup" --api-only >> "$fixture/api.log" 2>&1; then exit 1; fi
rm "$MISE_DATA_DIR/fail-api"
touch "$MISE_DATA_DIR/quota-exhausted"
if "$repo_root/bin/auth-setup" --api-only >> "$fixture/api.log" 2>&1; then exit 1; fi
rm "$MISE_DATA_DIR/quota-exhausted"
grep -q '1234567890' "$fixture/api.log"
[[ $(wc -l < "$MISE_DATA_DIR/calls" | tr -d ' ') == 1 ]]
! grep -q 'synthetic-credential-do-not-log' "$fixture/"*.log
# A newer complete installation is resolved without mise or PATH gh, even when
# the old version and mise's latest alias have gone away.
mkdir -p "$MISE_DATA_DIR/installs/gh/2.101.0/bin"
cp "$MISE_DATA_DIR/fake-gh" "$MISE_DATA_DIR/installs/gh/2.101.0/bin/gh"
[[ $("$HOME/bin/dotfiles-gh-real" --resolve) == */2.101.0/bin/gh ]]
# Intel archives retain a release directory too; ignore symlinked executables.
mkdir -p "$MISE_DATA_DIR/installs/gh/2.102.0/gh_2.102.0_macOS_amd64/bin"
cp "$MISE_DATA_DIR/fake-gh" "$MISE_DATA_DIR/installs/gh/2.102.0/gh_2.102.0_macOS_amd64/bin/gh"
[[ $("$HOME/bin/dotfiles-gh-real" --resolve) == */2.102.0/gh_2.102.0_macOS_amd64/bin/gh ]]
mkdir -p "$MISE_DATA_DIR/installs/gh/9.0.0/bin"
ln -s "$MISE_DATA_DIR/fake-gh" "$MISE_DATA_DIR/installs/gh/9.0.0/bin/gh"
[[ $("$HOME/bin/dotfiles-gh-real" --resolve) == */2.102.0/gh_2.102.0_macOS_amd64/bin/gh ]]
"$repo_root/bin/auth-setup" --verify-mise > "$fixture/mise.log" 2>&1
# Ordinary routing and explicit environment credentials remain authoritative.
printf 'default\tfixture-account\n' > "$fixture/routing"
GH_ACCOUNT_ROUTING_FILE="$fixture/routing" "$repo_root/home/bin/gh" api-test > "$fixture/token-private"
[[ $(cat "$fixture/token-private") == synthetic-credential-do-not-log ]]
GH_TOKEN=explicit GH_ACCOUNT_ROUTING_FILE="$fixture/routing" "$repo_root/home/bin/gh" api-test > "$fixture/token-private"
[[ $(cat "$fixture/token-private") == explicit ]]
# Published pin is validated locally, with no network scan, and reruns preserve it.
"$repo_root/bin/auth-setup" --verify-host
cp "$HOME/.ssh/known_hosts" "$fixture/known-hosts"
"$repo_root/bin/auth-setup" --verify-host
cmp "$HOME/.ssh/known_hosts" "$fixture/known-hosts"
ssh-keygen -q -t ed25519 -N '' -f "$fixture/host-fixture"
printf 'github.com %s\n' "$(cat "$fixture/host-fixture.pub")" > "$HOME/.ssh/known_hosts"
if "$repo_root/bin/auth-setup" --verify-host > "$fixture/host.log" 2>&1; then exit 1; fi
if "$repo_root/bin/auth-setup" --ssh-only > "$fixture/ssh.log" 2>&1; then exit 1; fi
"$repo_root/bin/auth-setup" --api-only >> "$fixture/api.log" 2>&1
# Isolated acquisition failure requests no broad inventory.
mv "$MISE_DATA_DIR/installs" "$MISE_DATA_DIR/saved-installs"
touch "$MISE_DATA_DIR/fail-acquire"
if "$repo_root/bin/github-bootstrap" > "$fixture/acquire-fail.log" 2>&1; then exit 1; fi
[[ $(wc -l < "$MISE_DATA_DIR/calls" | tr -d ' ') == 1 ]]
printf 'PASS: isolated acquisition, idempotency, API/403/quota gates, direct credentials, upgrade resolution, routing, published host validation\n'
