# Interactive mise installs and upgrades update installed vendor-owned agents,
# then bin/save-lock commits and pushes a changed lockfile on main.
# After a full install or an upgrade, the helper also deletes unused versions.
# It prunes only the tools in the global config, such as the old Bun after a pin
# change. A project whose mise.toml mise does not track (for example an
# untrusted one) keeps its tools.
_dotfiles_mise_prune_global() {
  local -a tools
  tools=(${${(f)"$(command mise ls --global --no-header 2>/dev/null)"}%% *})
  (( ${#tools} )) || return 0
  command mise prune --tools --yes --quiet -- "${(@u)tools}" ||
    print -u2 'mise prune failed; rerun: mise prune --tools <tool>'
}

mise() {
  local subcommand="${1:-}" argument prune=1
  case "$subcommand" in
    install|i|up|upgrade)
      for argument in "$@"; do
        case "$argument" in
          --dry-run|--dry-run-code|-n|--help|-h)
            command mise "$@"
            return $?
            ;;
        esac
      done
      command mise "$@" || return $?
      # `mise install TOOL@VERSION` keeps its version: no config selects it
      # yet, so prune would delete it.
      if [[ "$subcommand" == install || "$subcommand" == i ]]; then
        for argument in "${@:2}"; do
          [[ "$argument" == -* ]] || prune=0
        done
      fi
      if (( prune )); then
        _dotfiles_mise_prune_global
      fi
      "$HOME/bin/harness" update --installed-only
      "${DOTFILES_ROOT:-$HOME/development/dotfiles}/bin/save-lock"
      ;;
    *) command mise "$@" ;;
  esac
}
