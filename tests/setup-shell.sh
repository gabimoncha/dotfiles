#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-shell-test.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/home/.config/zsh" "$fixture/home/bin" "$fixture/home/.local/bin" "$fixture/home/.local/share/mise/shims" "$fixture/repo" "$fixture/other"
cp "$repo_root/home/.config/zsh/"*.zsh "$fixture/home/.config/zsh/"
cp "$repo_root/home/.zshrc" "$fixture/home/.zshrc"
cat > "$fixture/home/bin/brew" <<'STUB'
#!/bin/bash
[[ "$*" == shellenv ]] || exit 99
# Read-only environment probe, no real Homebrew is used by this fixture.
STUB
for tool in mise gh curl wget bun node npm; do
  cat > "$fixture/home/bin/$tool" <<'STUB'
#!/bin/bash
printf 'FORBIDDEN %s\n' "$0" >> "$FIXTURE_CALLS"
exit 99
STUB
done
for tool in zoxide sfw fzf; do
  cp "$fixture/home/bin/mise" "$fixture/home/.local/share/mise/shims/$tool"
done
cat > "$fixture/home/.local/bin/codex" <<'STUB'
#!/bin/bash
exit 0
STUB
cp "$fixture/home/bin/mise" "$fixture/other/codex"
chmod +x "$fixture/home/bin/"* "$fixture/home/.local/bin/codex" "$fixture/home/.local/share/mise/shims/"* "$fixture/other/codex"
run_shell() {
  env -i HOME="$fixture/home" DOTFILES_ROOT="$fixture/repo" \
    PATH="$fixture/home/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    FIXTURE_CALLS="$fixture/calls" FIXTURE_ROOT="$fixture" \
    /bin/zsh -dfc 'source "$HOME/.zshrc"; [[ $commands[codex] == "$HOME/.local/bin/codex" ]] || exit 2; [[ $path[1] == "$HOME/bin" && $path[2] == "$HOME/.local/bin" && ${path[(Ie)$HOME/.bun/bin]} -gt 0 ]] || exit 3; eval "$1"' -- "$1"
}
run_shell '! (( $+aliases[npm] )); ! (( $+functions[z] )); ! _dotfiles_real_tool zoxide >/dev/null' > "$fixture/startup.log" 2>&1
[[ ! -s "$fixture/calls" ]]
# Installed optional integrations are initialized directly, never via shims.
mkdir -p "$fixture/home/.local/share/mise/installs/zoxide/1.0.0/bin" "$fixture/home/.local/share/mise/installs/fzf/1.0.0/bin"
cat > "$fixture/home/.local/share/mise/installs/zoxide/1.0.0/bin/zoxide" <<'STUB'
#!/bin/bash
[[ "$*" == 'init zsh' ]] || exit 99
printf 'zoxide-direct\n' >> "$FIXTURE_CALLS"
printf 'function z() { :; }\n'
STUB
cat > "$fixture/home/.local/share/mise/installs/fzf/1.0.0/bin/fzf" <<'STUB'
#!/bin/bash
printf 'fzf-direct\n' >> "$FIXTURE_CALLS"
STUB
chmod +x "$fixture/home/.local/share/mise/installs/"*/*/bin/*
mkdir -p "$fixture/home/.oh-my-zsh/custom/plugins/zsh-fzf-history-search"
cat > "$fixture/home/.oh-my-zsh/oh-my-zsh.sh" <<'STUB'
for plugin in $plugins; do
  [[ -r "$ZSH/custom/plugins/$plugin/$plugin.plugin.zsh" ]] && source "$ZSH/custom/plugins/$plugin/$plugin.plugin.zsh"
done
# Mimic a plugin exposing an executable from another package.
path=("$FIXTURE_ROOT/other" $path)
STUB
cat > "$fixture/home/.oh-my-zsh/custom/plugins/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh" <<'STUB'
fzf --version
STUB
run_shell '(( $+functions[z] )); [[ " $plugins " == *" zsh-fzf-history-search "* ]]' >> "$fixture/startup.log" 2>&1
grep -q zoxide-direct "$fixture/calls"
grep -q fzf-direct "$fixture/calls"
! grep -q FORBIDDEN "$fixture/calls"
# A non-executable partial installation cannot enable an optional integration.
chmod -x "$fixture/home/.local/share/mise/installs/zoxide/1.0.0/bin/zoxide"
run_shell '! (( $+functions[z] )); ! _dotfiles_real_tool zoxide >/dev/null' >> "$fixture/startup.log" 2>&1
! grep -q FORBIDDEN "$fixture/calls"
printf 'PASS: offline incomplete shell, no mise/gh/network/provisioning calls, direct optional integrations, partial executable rejection, standalone priority\n'
