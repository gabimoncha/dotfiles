# Supported telemetry controls. Sources and coverage: apps/telemetry-audit.json.
# POSIX shell: used by setup, installers, zsh, and the GUI login job.
export HOMEBREW_NO_ANALYTICS=1
export BINSTALL_DISABLE_TELEMETRY=true
export MISE_USE_VERSIONS_HOST_TRACK=false
export MISE_OTEL_ENABLED=false
export MISE_OTEL_LOGS=false
export DO_NOT_TRACK=1
export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
export COCOAPODS_DISABLE_STATS=true
export FASTLANE_OPT_OUT_USAGE=YES
export DISABLE_EAS_ANALYTICS=1
export WRANGLER_SEND_METRICS=false
export WRANGLER_SEND_ERROR_REPORTS=false
export CF_SEND_TELEMETRY=false
export FLY_SEND_METRICS=false
export ENTIRE_TELEMETRY_OPTOUT=1
export T3CODE_TELEMETRY_ENABLED=false
export T3CODE_OTEL_SDK_DISABLED=true
export PI_TELEMETRY=0
export CTX7_TELEMETRY_DISABLED=1
export TURBO_TELEMETRY_DISABLED=1
export GH_TELEMETRY=false
# Docker CLI metric export is opt-in through this endpoint.
unset DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT
export VERCEL_TELEMETRY_DISABLED=1
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export CLAUDE_CODE_ENABLE_TELEMETRY=0
export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
# Zulu's built-in Connected Runtime Service uses comma-separated properties.
# Keep other properties and replace all existing enable entries.
_dotfiles_crs_remaining=${AZ_CRS_ARGUMENTS-}
_dotfiles_crs_kept=
while [ -n "$_dotfiles_crs_remaining" ]; do
  case "$_dotfiles_crs_remaining" in
    *,*)
      _dotfiles_crs_property=${_dotfiles_crs_remaining%%,*}
      _dotfiles_crs_remaining=${_dotfiles_crs_remaining#*,}
      ;;
    *)
      _dotfiles_crs_property=$_dotfiles_crs_remaining
      _dotfiles_crs_remaining=
      ;;
  esac
  case "$_dotfiles_crs_property" in
    enable|enable=*) ;;
    *) _dotfiles_crs_kept=${_dotfiles_crs_kept:+$_dotfiles_crs_kept,}$_dotfiles_crs_property ;;
  esac
done
export AZ_CRS_ARGUMENTS="${_dotfiles_crs_kept:+$_dotfiles_crs_kept,}enable=false"
unset _dotfiles_crs_remaining _dotfiles_crs_kept _dotfiles_crs_property
