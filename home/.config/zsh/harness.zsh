# Native postinstall hooks cover direct mise installs and upgrades with changes.
# This helper also covers upgrades that have no new mise versions to install.
# After a full install or an upgrade, the helper also deletes unused versions.
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
      DOTFILES_HARNESS_SKIP_HOOK=1 command mise "$@" || return $?
      # `mise install TOOL@VERSION` keeps its version: no config selects it
      # yet, so prune would delete it.
      if [[ "$subcommand" == install || "$subcommand" == i ]]; then
        for argument in "${@:2}"; do
          [[ "$argument" == -* ]] || prune=0
        done
      fi
      if (( prune )); then
        command mise prune --yes --quiet || print -u2 'mise prune failed; rerun: mise prune'
      fi
      "$HOME/bin/harness" update --installed-only
      ;;
    *) command mise "$@" ;;
  esac
}
