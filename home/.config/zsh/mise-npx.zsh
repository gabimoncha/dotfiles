# Mise-aware one-off npm package runner for zsh.
#
# What this gives you:
# - `npx <pkg>` and `px <pkg>` run through the package manager selected by mise.
# - `bx <pkg>` remains an explicit Bun escape hatch.
# - Project-local `mise.toml` settings override your global mise config.
#
# To adopt this in another zsh setup:
# 1. Install mise and activate it before sourcing this file:
#      eval "$(mise activate zsh)"
# 2. Set your preferred global default:
#      mise settings set npm.package_manager bun
#    or add this to `~/.config/mise/config.toml`:
#      [settings.npm]
#      package_manager = "bun"
# 3. Optionally override per project in `mise.toml`:
#      [settings.npm]
#      package_manager = "pnpm"
# 4. Source this file from `.zshrc` after mise activation:
#      [ -r "$HOME/.config/zsh/mise-npx.zsh" ] && source "$HOME/.config/zsh/mise-npx.zsh"
#
# Supported mise values are `bun`, `pnpm`, `aube`, and `auto`. This wrapper
# deliberately refuses `npm` and `yarn`, and treats `auto` as aubx -> bunx ->
# pnpm without falling back to npm.

_mise_npm_package_manager() {
  local manager

  if ! command -v mise >/dev/null 2>&1; then
    print -u2 "npx: mise is required to resolve npm.package_manager"
    return 1
  fi

  if ! manager="$(mise settings get npm.package_manager)"; then
    print -u2 "npx: could not read mise npm.package_manager"
    return 1
  fi

  case "$manager" in
    bun|pnpm|aube|auto)
      print -r -- "$manager"
      ;;
    npm|yarn)
      print -u2 "npx: mise selected '$manager', but this shell wrapper only allows bun, pnpm, aube, or non-npm auto"
      return 1
      ;;
    "")
      print -u2 "npx: mise did not return npm.package_manager"
      return 1
      ;;
    *)
      print -u2 "npx: unsupported mise npm.package_manager '$manager'"
      return 1
      ;;
  esac
}

_mise_npm_auto_package_manager() {
  if command -v aubx >/dev/null 2>&1; then
    print -r -- "aube"
  elif command -v bunx >/dev/null 2>&1; then
    print -r -- "bun"
  elif command -v pnpm >/dev/null 2>&1; then
    print -r -- "pnpm"
  else
    print -u2 "npx: mise npm.package_manager is auto, but no aubx, bunx, or pnpm runner is on PATH"
    return 1
  fi
}

_mise_npm_effective_package_manager() {
  local manager

  manager="$(_mise_npm_package_manager)" || return
  if [[ "$manager" == "auto" ]]; then
    _mise_npm_auto_package_manager
  else
    print -r -- "$manager"
  fi
}

_mise_npm_require_runner() {
  case "$1" in
    bun)
      command -v bunx >/dev/null 2>&1 || {
        print -u2 "npx: mise selected bun, but bunx is not on PATH"
        return 1
      }
      ;;
    pnpm)
      command -v pnpm >/dev/null 2>&1 || {
        print -u2 "npx: mise selected pnpm, but pnpm is not on PATH"
        return 1
      }
      ;;
    aube)
      command -v aubx >/dev/null 2>&1 || {
        print -u2 "npx: mise selected aube, but aubx is not on PATH"
        return 1
      }
      ;;
    *)
      print -u2 "npx: unsupported runner '$1'"
      return 1
      ;;
  esac
}

_npx_reject_unsupported_leading_flags() {
  local arg

  while (( $# > 0 )); do
    arg="$1"

    case "$arg" in
      --)
        return 0
        ;;
      --help|-h)
        return 0
        ;;
      --package|-p)
        if (( $# < 2 )); then
          print -u2 "npx: $arg requires a package name"
          return 1
        fi
        shift 2
        ;;
      --package=*|--silent|--verbose)
        shift
        ;;
      --*)
        print -u2 "npx: unsupported npx option '$arg' for the mise-aware wrapper"
        print -u2 "npx: use 'command npx $arg ...' for npm's real npx, or use bx/bunx for Bun-specific flags"
        return 1
        ;;
      -*)
        print -u2 "npx: unsupported npx option '$arg' for the mise-aware wrapper"
        print -u2 "npx: use 'command npx $arg ...' for npm's real npx"
        return 1
        ;;
      *)
        return 0
        ;;
    esac
  done
}

npx() {
  local manager

  while [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; do
    shift
  done

  _npx_reject_unsupported_leading_flags "$@" || return

  manager="$(_mise_npm_effective_package_manager)" || return
  _mise_npm_require_runner "$manager" || return

  case "$manager" in
    bun)
      command bunx "$@"
      ;;
    pnpm)
      command pnpm dlx "$@"
      ;;
    aube)
      command aubx "$@"
      ;;
  esac
}

px() {
  npx "$@"
}

alias bx='bunx'
