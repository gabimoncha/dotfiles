# Native postinstall hooks cover direct mise installs and upgrades with changes.
# This helper also covers upgrades that have no new mise versions to install.
# Both delete unused tool versions, then update the vendor-owned agents.
mise() {
  local subcommand="${1:-}" argument
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
      command mise prune --yes --quiet || print -u2 'mise prune failed; rerun: mise prune'
      "$HOME/bin/harness" update --installed-only
      ;;
    *) command mise "$@" ;;
  esac
}
