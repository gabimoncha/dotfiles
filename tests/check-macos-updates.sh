#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
fake_softwareupdate="${temp_dir}/softwareupdate"
failures=0

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

printf '%s\n' \
  '#!/usr/bin/env bash' \
  '[[ "$*" == "--list --product-types macOS" ]] || exit 91' \
  '[[ "${LC_ALL:-}" == "C" && "${LANG:-}" == "C" ]] || exit 92' \
  'if [[ "${TEST_SOFTWAREUPDATE_HANG:-0}" == 1 ]]; then while :; do sleep 1; done; fi' \
  'printf "%s\n" "${TEST_SOFTWAREUPDATE_OUTPUT:-}"' \
  'exit "${TEST_SOFTWAREUPDATE_STATUS:-0}"' >"$fake_softwareupdate"
chmod +x "$fake_softwareupdate"

run_case() {
  local name="$1"
  local expected_status="$2"
  local expected_text="$3"
  local output status

  set +e
  output="$(DOTFILES_SOFTWAREUPDATE_BIN="$fake_softwareupdate" \
    TEST_SOFTWAREUPDATE_OUTPUT="$TEST_SOFTWAREUPDATE_OUTPUT" \
    TEST_SOFTWAREUPDATE_STATUS="${TEST_SOFTWAREUPDATE_STATUS:-0}" \
    TEST_SOFTWAREUPDATE_HANG="${TEST_SOFTWAREUPDATE_HANG:-0}" \
    DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS="${DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS:-}" \
    "${repo_root}/bin/check-macos-updates" 2>&1)"
  status=$?
  set -e

  if [[ $status -eq $expected_status && "$output" == *"$expected_text"* ]]; then
    printf 'ok  - %s\n' "$name"
  else
    printf 'fail - %s: status=%s output=%s\n' "$name" "$status" "$output" >&2
    failures=$((failures + 1))
  fi
}

TEST_SOFTWAREUPDATE_OUTPUT=$'Software Update Tool\n\nFinding available software\nNo new software available.'
TEST_SOFTWAREUPDATE_STATUS=0
run_case "known no-update output passes" 0 "no macOS updates are available"

TEST_SOFTWAREUPDATE_OUTPUT=$'Software Update Tool\n\nFinding available software\nSoftware Update found the following new or updated software:\n* Label: macOS Sequoia 15.7.4-24G517\n\tTitle: macOS Sequoia 15.7.4, Version: 15.7.4, Recommended: YES, Action: restart,'
run_case "known update output fails" 1 "a macOS update is available"

TEST_SOFTWAREUPDATE_OUTPUT=$'Software Update Tool\n\nFinding available software\nSoftware Update found the following new or updated software:\n- Label: macOS Sequoia 15.7.4-24G517\n\tTitle: macOS Sequoia 15.7.4, Version: 15.7.4, Recommended: NO, Action: restart,'
run_case "known non-recommended update output fails" 1 "a macOS update is available"

TEST_SOFTWAREUPDATE_OUTPUT="network unavailable"
TEST_SOFTWAREUPDATE_STATUS=7
run_case "command failure is unknown" 1 "unknown because softwareupdate exited with status 7"

TEST_SOFTWAREUPDATE_OUTPUT=$'Software Update Tool\n\nFinding available software\nA new output format'
TEST_SOFTWAREUPDATE_STATUS=0
run_case "unexpected output is unknown" 1 "unknown because softwareupdate returned unexpected output"

TEST_SOFTWAREUPDATE_OUTPUT=$'No new software available.\nSoftware Update found the following new or updated software:\n* Label: conflicting-output'
run_case "ambiguous output is unknown" 1 "unknown because softwareupdate returned unexpected output"

TEST_SOFTWAREUPDATE_OUTPUT=""
TEST_SOFTWAREUPDATE_STATUS=0
TEST_SOFTWAREUPDATE_HANG=1
DOTFILES_SOFTWAREUPDATE_TIMEOUT_SECONDS=1
run_case "hung command times out" 1 "unknown because softwareupdate timed out after 1 seconds"

if [[ $failures -ne 0 ]]; then
  exit 1
fi
