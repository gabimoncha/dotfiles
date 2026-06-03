# Minimal Powerlevel10k prompt. Run `p10k configure` locally for machine-specific tuning.

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
