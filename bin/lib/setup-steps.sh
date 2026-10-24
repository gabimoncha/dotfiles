#!/usr/bin/env bash
# The functions that bin/setup runs as steps, and their helpers. bin/setup sets
# repo_root and loads bin/lib/setup-runtime.sh first. Bash 3.2 compatible.
macos_defaults_flag="${HOME}/.macos-defaults-applied"
temp_brewfile=""
xcode_brewfile=""
mas_brewfile=""
cursor_extensions_brewfile=""
mas_checked=0
mas_available=0
homebrew_xcode_checked=0
homebrew_xcode_too_old=0
mise_bin_dir="${HOME}/.local/bin"
mise_shim_dir="${HOME}/.local/share/mise/shims"
brew_bundle_jobs="${DOTFILES_BREW_BUNDLE_JOBS:-auto}"

log() {
  printf '==> %s\n' "$1"
}

warn() {
  printf '!! %s\n' "$1" >&2
}

prepend_mise_shims() {
  local path_entry
  local new_path="${mise_bin_dir}:${mise_shim_dir}"
  local path_entries=()

  IFS=':' read -r -a path_entries <<< "$PATH"
  for path_entry in "${path_entries[@]}"; do
    [[ -z "$path_entry" ]] && continue
    case "$path_entry" in
      "$mise_bin_dir" | "$mise_shim_dir") continue ;;
    esac
    new_path="${new_path}:${path_entry}"
  done

  export PATH="$new_path"
}

ensure_not_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    warn "Do not run ./bin/setup with sudo or as root."
    warn "Run: ./bin/setup"
    warn "The script will ask for sudo only when a specific privileged step needs it."
    exit 1
  fi
}

ensure_admin_user() {
  if id -Gn | tr ' ' '\n' | grep -qx admin; then
    return 0
  fi

  warn "Homebrew needs sudo access on macOS."
  warn "Add this user to the admin group or run setup from an administrator account."
  exit 1
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew is installed"
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew || -x /usr/local/bin/brew ]]; then
    log "Homebrew is installed but not on PATH"
    return 0
  fi

  log "Installing Homebrew"
  warn "Homebrew may ask for your macOS password to create its install directories."
  local installer status=0
  installer="$(mktemp)" || return 1
  curl -fsSL --connect-timeout 15 --max-time 120 --retry 2 --retry-max-time 180 \
    https://raw.githubusercontent.com/Homebrew/install/8949852f785a3bacaba2a979d0790337950b0a4a/install.sh -o "$installer" || status=$?
  if [[ "$status" -eq 0 ]]; then
    NONINTERACTIVE=1 runtime_with_lock homebrew /bin/bash "$installer" || status=$?
  fi
  rm -f "$installer"
  return "$status"
}

load_homebrew_shellenv() {
  if [[ -n "${HOMEBREW_PREFIX:-}" && -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi

  warn "Homebrew installed, but brew was not found on PATH."
  return 1
}

cask_app_bundle_name() {
  case "$1" in
    beeper) printf 'Beeper Desktop' ;;
    blackhole-2ch) printf 'BlackHole 2ch' ;;
    claude) printf 'Claude' ;;
    cursor) printf 'Cursor' ;;
    discord) printf 'Discord' ;;
    expo-orbit) printf 'Orbit' ;;
    figma) printf 'Figma' ;;
    font-hack-nerd-font) printf '' ;;
    ghostty) printf 'Ghostty' ;;
    google-chrome) printf 'Google Chrome' ;;
    helium-browser) printf 'Helium' ;;
    iina) printf 'IINA' ;;
    iterm2) printf 'iTerm' ;;
    karabiner-elements) printf 'Karabiner-Elements' ;;
    mole-app) printf 'Mole' ;;
    neardrop | grishka/grishka/neardrop) printf 'NearDrop' ;;
    ngrok) printf 'ngrok' ;;
    nikitabobko/tap/aerospace | aerospace) printf 'AeroSpace' ;;
    notion-calendar) printf 'Notion Calendar' ;;
    obs) printf 'OBS' ;;
    obsidian) printf 'Obsidian' ;;
    orbstack) printf 'OrbStack' ;;
    pgadmin4) printf 'pgAdmin 4' ;;
    raycast) printf 'Raycast' ;;
    signal) printf 'Signal' ;;
    slack) printf 'Slack' ;;
    spotify) printf 'Spotify' ;;
    superwhisper) printf 'superwhisper' ;;
    synology-drive) printf 'Synology Drive Client' ;;
    synology-image-assistant) printf 'Synology Image Assistant' ;;
    t3-code@nightly) printf 'T3 Code (Nightly)' ;;
    tailscale-app) printf 'Tailscale' ;;
    the-unarchiver) printf 'The Unarchiver' ;;
    whatsapp) printf 'WhatsApp' ;;
    yaak) printf 'Yaak' ;;
    zen) printf 'Zen' ;;
    zoom) printf 'zoom.us' ;;
    zulu@17) printf '' ;;
    *) printf '' ;;
  esac
}

# borders fails to build when Homebrew reports the Xcode app as too old.
homebrew_xcode_sensitive_formula() {
  [[ "$1" == borders ]]
}

homebrew_reports_xcode_too_old() {
  local doctor_output

  if [[ "$homebrew_xcode_checked" -eq 1 ]]; then
    [[ "$homebrew_xcode_too_old" -eq 1 ]]
    return $?
  fi

  homebrew_xcode_checked=1

  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  doctor_output="$(brew doctor 2>&1 || true)"
  if grep -q 'Your Xcode .* is too outdated' <<< "$doctor_output"; then
    homebrew_xcode_too_old=1
    return 0
  fi

  return 1
}

resolve_mas_cli() {
  local candidate
  candidate="$(command -v mas 2>/dev/null || true)"
  case "$candidate" in
    *'/shims/'*) candidate="$("$repo_root/bin/repo-mise" --global which mas 2>/dev/null)" || return 1 ;;
  esac
  [[ -n "$candidate" && -x "$candidate" ]] || return 1
  "$candidate" version >/dev/null 2>&1 || "$candidate" --version >/dev/null 2>&1 || return 1
  printf '%s\n' "$candidate"
}

mas_available_for_brewfile() {
  if [[ $mas_checked -eq 1 ]]; then
    [[ $mas_available -eq 1 ]]
    return $?
  fi

  mas_checked=1

  if ! mas_cmd="$(resolve_mas_cli)"; then
    warn "Skipping Mac App Store apps; mas is managed by mise. Check its installation and App Store sign-in, then rerun ./bin/setup --continue."
    return 1
  fi

  if "$mas_cmd" config >/dev/null 2>&1; then
    mas_available=1
    return 0
  fi

  warn "Skipping Mac App Store apps; mas is installed but the App Store is not usable yet. Sign in, then rerun ./bin/setup."
  return 1
}

mas_app_installed() {
  local app_id="$1"

  "${mas_cmd:-mas}" list | awk '{print $1}' | grep -Fxq "$app_id"
}

install_mas_apps() {
  local line app_name app_id app_bundle status=0

  if [[ ! -s "$mas_brewfile" ]]; then
    return 0
  fi

  if ! mas_available_for_brewfile; then
    runtime_record_deferred "Mac App Store apps" "mas is unavailable or App Store is not signed in" "Sign in to the App Store, then rerun ./bin/setup."
    return 20
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\"\,\ id:\ ([0-9]+) ]]; then
      app_name="${BASH_REMATCH[1]}"
      app_id="${BASH_REMATCH[2]}"
      app_bundle="$app_name"

      if [[ -d "/Applications/${app_bundle}.app" ]]; then
        log "${app_bundle}.app already exists"
        continue
      fi

      if mas_app_installed "$app_id"; then
        log "App Store app ${app_name} already installed"
        continue
      fi

      log "Installing App Store app ${app_name}"
      # mas 7 needs root to install apps.
      sudo "$mas_cmd" install "$app_id" || {
        warn "Skipping ${app_name}; App Store did not start the download. Open it in the App Store once, then rerun ./bin/setup."
        runtime_record_failure recoverable "App Store app ${app_name}" "mas install did not start the download" "" "Open ${app_name} in the App Store once, then rerun ./bin/setup."
        status=1
      }
    fi
  done < "$mas_brewfile"

  return "$status"
}

cursor_cli() {
  if command -v cursor >/dev/null 2>&1; then
    command -v cursor
    return 0
  fi

  if [[ -x "${DOTFILES_APPLICATIONS_DIR:-/Applications}/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
    printf '%s/Cursor.app/Contents/Resources/app/bin/cursor\n' "${DOTFILES_APPLICATIONS_DIR:-/Applications}"
    return 0
  fi

  return 1
}

install_cursor_extensions() {
  local cursor_cmd line extension_id installed_extensions status=0

  if [[ ! -s "$cursor_extensions_brewfile" ]]; then
    return 0
  fi

  cursor_cmd="$(cursor_cli || true)"
  if [[ -z "$cursor_cmd" ]]; then
    warn "Skipped Cursor extensions; Cursor editor CLI is not available yet"
    runtime_record_deferred "Cursor extensions" "Cursor editor CLI is not available yet" "Open Cursor once or rerun ./bin/setup after the cask install completes."
    return 20
  fi

  installed_extensions="$("$cursor_cmd" --list-extensions 2>/dev/null || true)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^vscode[[:space:]]+\"([^\"]+)\" ]]; then
      extension_id="${BASH_REMATCH[1]}"

      if grep -Fixq "$extension_id" <<< "$installed_extensions"; then
        log "Cursor extension ${extension_id} already installed"
        continue
      fi

      log "Installing Cursor extension ${extension_id}"
      "$cursor_cmd" --install-extension "$extension_id" || {
        warn "Skipping Cursor extension ${extension_id}; it is unavailable or failed to install"
        runtime_record_failure recoverable "Cursor extension ${extension_id}" "extension install failed" "" "Rerun ./bin/setup after Cursor is ready."
        status=1
      }
    fi
  done < "$cursor_extensions_brewfile"

  return "$status"
}

untap_if_present() {
  local tap="$1"
  local replacement="$2"

  if ! brew tap | grep -Fxq "$tap"; then
    return 0
  fi

  warn "Untapping legacy Homebrew tap ${tap}; ${replacement} is the managed source"
  runtime_with_lock homebrew brew untap --force "$tap" || warn "Could not untap ${tap}; Homebrew may still report duplicate formulae"
}

normalize_homebrew_taps() {
  untap_if_present "zegervdv/zathura" "homebrew-zathura/zathura"
}

legacy_zathura_receipts_present() {
  local formula cellar receipt
  local formulae=(
    zathura-cb
    zathura-pdf-mupdf
  )

  for formula in "${formulae[@]}"; do
    cellar="$(brew --cellar "$formula" 2>/dev/null || true)"
    [[ -d "$cellar" ]] || continue

    while IFS= read -r receipt; do
      if grep -q 'zegervdv/zathura' "$receipt"; then
        return 0
      fi
    done < <(find "$cellar" -name INSTALL_RECEIPT.json -print 2>/dev/null)
  done

  return 1
}

repair_legacy_zathura_receipts() {
  if ! legacy_zathura_receipts_present; then
    return 0
  fi

  warn "Reinstalling zathura plugins to update legacy Homebrew receipt metadata"
  runtime_with_lock homebrew brew reinstall --formula \
    homebrew-zathura/zathura/zathura-cb \
    homebrew-zathura/zathura/zathura-pdf-mupdf || \
    warn "Could not update zathura plugin receipts; Homebrew may keep warning about the old zegervdv/zathura tap"
}

filter_brewfile_for_existing_apps() {
  local source_file="$1"
  local target_file="$2"
  local deferred_xcode_file="$3"
  local mas_file="$4"
  local extensions_file="$5"
  local line brew_name cask_name app_name mas_name mas_id mas_bundle

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
      brew_name="${BASH_REMATCH[1]}"

      if homebrew_xcode_sensitive_formula "$brew_name"; then
        if homebrew_reports_xcode_too_old; then
          warn "Deferring ${brew_name}; Homebrew requires a newer Xcode app"
          printf '# Deferred until Homebrew accepts the installed Xcode app: %s\n' "$line" >> "$target_file"
          printf '%s\n' "$line" >> "$deferred_xcode_file"
          continue
        fi
      fi
    fi

    if [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\"\,\ id:\ ([0-9]+) ]]; then
      mas_name="${BASH_REMATCH[1]}"
      mas_id="${BASH_REMATCH[2]}"
      mas_bundle="$mas_name"

      printf '# Installed separately by bootstrap: %s\n' "$line" >> "$target_file"

      if [[ -d "/Applications/${mas_bundle}.app" ]]; then
        warn "Skipping App Store app ${mas_name}; /Applications/${mas_bundle}.app already exists"
        continue
      elif command -v mas >/dev/null 2>&1 && mas_app_installed "$mas_id"; then
        warn "Skipping App Store app ${mas_name}; already installed"
        continue
      fi

      printf '%s\n' "$line" >> "$mas_file"
      continue
    fi

    if [[ "$line" =~ ^vscode[[:space:]]+\"([^\"]+)\" ]]; then
      printf '# Installed separately by bootstrap: %s\n' "$line" >> "$target_file"
      printf '%s\n' "$line" >> "$extensions_file"
      continue
    fi

    if [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
      cask_name="${BASH_REMATCH[1]}"
      app_name="$(cask_app_bundle_name "$cask_name")"

      if [[ -n "$app_name" && -d "/Applications/${app_name}.app" ]]; then
        warn "Skipping cask ${cask_name}; /Applications/${app_name}.app already exists"
        printf '# Skipped existing app: %s\n' "$line" >> "$target_file"
        continue
      fi
    fi

    printf '%s\n' "$line" >> "$target_file"
  done < "$source_file"
}

prepare_brewfiles() {
  # Predictable per-run paths also work when the inventory runs in a child.
  temp_brewfile="${DOTFILES_SETUP_LOG_DIR}/homebrew.Brewfile"
  xcode_brewfile="${DOTFILES_SETUP_LOG_DIR}/xcode.Brewfile"
  mas_brewfile="${DOTFILES_SETUP_LOG_DIR}/mas.Brewfile"
  cursor_extensions_brewfile="${DOTFILES_SETUP_LOG_DIR}/cursor-extensions.Brewfile"
  : > "$temp_brewfile"
  : > "$xcode_brewfile"
  : > "$mas_brewfile"
  : > "$cursor_extensions_brewfile"
  filter_brewfile_for_existing_apps "${repo_root}/Brewfile" "$temp_brewfile" "$xcode_brewfile" "$mas_brewfile" "$cursor_extensions_brewfile"
}

install_brewfile() {
  command -v brew >/dev/null 2>&1 || return 1
  normalize_homebrew_taps
  repair_legacy_zathura_receipts
  [[ -n "$temp_brewfile" && -f "$temp_brewfile" ]] || prepare_brewfiles
  log "Installing Homebrew bundle with ${brew_bundle_jobs} parallel job(s)"
  runtime_with_lock homebrew brew bundle install --jobs="$brew_bundle_jobs" --no-upgrade --verbose --file "$temp_brewfile"
}

initialize_submodules() {
  log "Initializing git submodules"
  git -C "$repo_root" submodule sync --recursive || return $?
  git -C "$repo_root" submodule update --init --recursive || {
    warn "Submodule init failed. Check network access and rerun: git submodule update --init --recursive"
    return 1
  }
}

install_mise_tools_unlocked() {
  local status=0 refresh_status=0
  "${repo_root}/bin/repo-mise" --global install || status=$?
  # Successful downloads must remain usable even if another backend failed.
  "${repo_root}/bin/repo-mise" --global reshim || refresh_status=$?
  [[ "$status" -ne 0 ]] || status="$refresh_status"
  return "$status"
}

install_mise_tools() {
  prepend_mise_shims
  command -v mise >/dev/null 2>&1 || return 1
  runtime_with_lock mise install_mise_tools_unlocked
}

install_and_check_mise_tools() {
  local install_status=0 check_status=0
  install_mise_tools || install_status=$?
  "${repo_root}/bin/check-mise-tools" || check_status=$?
  [[ "$install_status" -eq 0 ]] || return "$install_status"
  return "$check_status"
}

# Update only missing checkouts. Native repos apply stops at the first conflict.
install_shell_framework() {
  local status_json missing_list path missing=()
  status_json="$("${repo_root}/bin/repo-mise" bootstrap repos status --json)" || return
  missing_list="$(/usr/bin/ruby -rjson -e '
    JSON.parse(STDIN.read).fetch("repos").each do |repo|
      case repo["state"]
      when "missing" then puts repo["path"]
      when "current" then nil
      else warn "!! Leaving #{repo["path"]} as it is: #{repo["state"]} #{repo["reason"]}".strip
      end
    end
  ' <<< "$status_json")" || return
  while IFS= read -r path; do
    [[ -n "$path" ]] && missing+=("$path")
  done <<< "$missing_list"
  if [[ ${#missing[@]} -eq 0 ]]; then
    log "Shell framework repositories are present"
    return 0
  fi
  log "Cloning shell framework repositories: ${missing[*]}"
  "${repo_root}/bin/repo-mise" bootstrap repos update --yes "${missing[@]}"
}

apply_macos_defaults_once() {
  local defaults_script="${repo_root}/macos/defaults.sh"
  local defaults_config="${repo_root}/mise.macos.toml"
  local status=0

  runtime_acquire_lock "macos-defaults" "macOS defaults" || return 1

  if [[ "${DOTFILES_SKIP_MACOS_DEFAULTS:-}" == "1" ]]; then
    warn "Skipping macOS defaults because DOTFILES_SKIP_MACOS_DEFAULTS=1"
    runtime_release_lock "macos-defaults"
    return 0
  fi

  if [[ -f "$macos_defaults_flag" && ! "$defaults_script" -nt "$macos_defaults_flag" &&
    ! "$defaults_config" -nt "$macos_defaults_flag" ]]; then
    log "macOS defaults already applied"
    runtime_release_lock "macos-defaults"
    return 0
  fi

  log "Applying macOS defaults"
  set +e
  "$defaults_script"
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    touch "$macos_defaults_flag"
  fi
  runtime_release_lock "macos-defaults"
  return "$status"
}

# Prints the real path of a tool that mise or the system installed. Shims and
# repository wrappers do not count.
setup_real_tool() {
  local tool="$1" candidate
  if [[ -x "${HOME}/.local/bin/mise" ]]; then
    candidate="$(MISE_AUTO_INSTALL=0 "$repo_root/bin/repo-mise" --global which "$tool" 2>/dev/null)" || candidate=""
    case "$candidate" in */shims/*) candidate="" ;; esac
    if [[ -n "$candidate" && -x "$candidate" ]]; then printf '%s\n' "$candidate"; return; fi
  fi
  candidate="$(command -v "$tool" 2>/dev/null)" || return 1
  case "$candidate" in /*/shims/*|*/configs/gh/gh|"$HOME/bin/gh") return 1 ;; esac
  [[ "$candidate" == /* && -x "$candidate" ]] || return 1
  printf '%s\n' "$candidate"
}

# Steps. bin/setup lists them in order.
setup_preflight() { "${repo_root}/bin/preflight"; }
setup_clt() {
  if xcode-select -p >/dev/null 2>&1; then return 0; fi
  xcode-select --install || true
  warn 'Finish the Command Line Tools installer, then rerun ./bin/setup.'
  return 1
}
setup_touch_id() { "${repo_root}/bin/configure-sudo-touch-id" --enable; }
setup_sudo() { ensure_admin_user; sudo -v; }
setup_linux_sudo() { sudo -v; }
# apt packages and the zsh login shell. mise uses sudo for both.
setup_linux_system() {
  "${repo_root}/bin/repo-mise" bootstrap --only packages,user --yes
}
setup_sudo_grant() {
  "${repo_root}/bin/sudo-grant" --enable || return
  # bin/setup removes only a grant that this run installed.
  : > "${DOTFILES_SETUP_LOG_DIR}/sudo-grant-installed"
}
setup_keepalive() {
  local owner=$$
  # A shared timestamp outlives this loop, so the loop must not outlive setup.
  (while kill -0 "$owner" 2>/dev/null && sudo -n true; do sleep 30; done) >/dev/null 2>&1 &
}
setup_homebrew() { ensure_homebrew; }
setup_mise() { "${repo_root}/bin/install-standalone" install mise; }
setup_install_gh() { "${repo_root}/bin/github-bootstrap" install-gh; }
setup_api() { "${repo_root}/bin/auth-setup" --api-only; }
setup_ssh() { "${repo_root}/bin/auth-setup" --ssh-only; }
setup_git_https() { "${repo_root}/bin/auth-setup" --git-only; }
setup_verify_auth() { "${repo_root}/bin/auth-setup" --verify-mise; }
setup_links() { "${repo_root}/bin/link-dotfiles" --skip-agents; }
setup_final_links() { "${repo_root}/bin/link-dotfiles"; }
setup_brew_environment() { load_homebrew_shellenv; }
setup_brewfiles() {
  log "Preparing Homebrew inventory (checking existing apps; no casks installed in this step)"
  prepare_brewfiles
}
setup_brew_inventory() { install_brewfile; }
setup_mise_inventory() {
  # The large mise install needs verified GitHub API access. See DECISIONS.md.
  if [[ "${DOTFILES_SETUP_API_READY:-0}" != 1 && "${DOTFILES_SKIP_GITHUB_AUTH:-0}" != 1 ]]; then
    warn "Skipped the mise install: GitHub API access is not verified. Run ./bin/auth-setup --api-only, then rerun setup."
    return 1
  fi
  install_and_check_mise_tools
}
setup_manifest_apps() { "${repo_root}/bin/install-apps"; }
setup_app_store() { install_mas_apps; }
setup_editor_extensions() { install_cursor_extensions; }
setup_submodules() { initialize_submodules; }
setup_shell() {
  local status=0
  install_shell_framework || status=1
  local tmux_path
  if tmux_path="$(setup_real_tool tmux)"; then PATH="$(dirname "$tmux_path"):$PATH" "${repo_root}/bin/setup-tmux" || status=1; fi
  return "$status"
}
setup_standalone_agents() {
  if [[ "${DOTFILES_SETUP_PHASE:-continue}" == prepare ]]; then
    "${repo_root}/bin/install-standalone" install --first-only
  else
    "${repo_root}/bin/install-standalone" install
  fi
}
setup_telemetry() { "${repo_root}/bin/configure-telemetry"; }
setup_app_settings() { "${repo_root}/bin/configure-app-settings"; }
setup_screenshots() { "${repo_root}/bin/configure-screenshots"; }
setup_permission_handoff() {
  cat <<'INSTRUCTIONS'
Foundation installation finished. This phase does not install the bulk app inventory.

Before continuing:
0. Open the App Store app and sign in. Continuation installs App Store apps,
   including Xcode, without another sign-in prompt.
1. Open System Settings > Privacy & Security > App Management.
2. Enable the terminal application you will use for setup, if listed; use Add
   if macOS offers it. Approve App Management when macOS requests it.
   Setup cannot grant or reliably verify this permission. If the app is not
   available to select, the first protected app operation may still prompt.
3. Once this command exits, fully quit and reopen that terminal application
   (not just its tab), as requested by macOS. Stop other work in it first.
4. Return to this repository and run: ./bin/setup --continue

--continue acknowledges this manual checkpoint; it does not assert that macOS
permissions were detected. Do not grant Full Disk Access or Accessibility just
for package installation. App-specific consent is handled later, as needed.
Both phases retain live output and private diagnostic logs.
INSTRUCTIONS
}
setup_mobile() { "${repo_root}/bin/install-mobile-dev"; }
setup_skills() {
  local source_ref="${DOTFILES_REVIEWED_SKILLS_REF:-}" node
  # Mutable remote skill code is not silently trusted during recovery.
  if [[ ! "$source_ref" =~ ^[0-9a-f]{40}$ ]]; then
    runtime_record_deferred 'Personal skills' 'set DOTFILES_REVIEWED_SKILLS_REF to a reviewed repository commit' 'Review the skill source, then rerun setup with the reviewed commit.'
    return 20
  fi
  node="$(setup_real_tool node)" || return 1
  # Require a reviewed installed skills CLI rather than executing latest code.
  local skills
  skills="$(setup_real_tool skills)" || { warn 'Install a reviewed skills CLI version explicitly before importing skills.'; return 20; }
  PATH="$(dirname "$node"):$PATH" "$skills" --version >/dev/null 2>&1 || return 1
  PATH="$(dirname "$node"):$PATH" "$skills" add "https://github.com/gabimoncha/skills/tree/${source_ref}" -g --skill '*' --agent claude-code cursor codex -y
}
setup_defaults() { apply_macos_defaults_once; }
setup_finder() { "${repo_root}/bin/finder-sidebar-favorites"; }

setup_verify_apps() {
  local key type token bundle notes status=0
  while IFS=$'\t' read -r key type token bundle notes || [[ -n "${key:-}" ]]; do
    [[ -n "${key:-}" && "$key" != \#* ]] || continue
    case "$type" in
      cask|script)
        if [[ "$bundle" != - && -n "$bundle" ]]; then
          if [[ ! -d "${DOTFILES_APPLICATIONS_DIR:-/Applications}/${bundle}.app" ]]; then
            runtime_record_failure recoverable "app.$key" "application bundle is unavailable"
            status=1
          fi
        elif ! brew list --cask "$token" >/dev/null 2>&1; then status=1; fi
        ;;
      formula) brew list --formula "$token" >/dev/null 2>&1 || status=1 ;;
      manual)
        [[ -d "${DOTFILES_APPLICATIONS_DIR:-/Applications}/${bundle}.app" ]] || runtime_record_deferred "app.$key" 'vendor installation requires manual completion'
        ;;
    esac
  done < "${repo_root}/apps/manifest.tsv"
  return "$status"
}
