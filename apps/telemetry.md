# Telemetry controls

Reviewed on 2026-10-03. Coverage: 195 of 195 tracked entries.

Setup exports the supported environment controls before installers run. It applies saved preferences after foundation installation, and again at the end of continuation after restores. A failed setter makes the stage fail; other installed tools are still configured.

Run `./bin/configure-telemetry --dry-run` to preview the changes. Run it without that option to retry. Existing configuration is merged and backed up. Complex Codex telemetry tables and escaped names are left unchanged and reported for manual repair. The TOML merger handles standard telemetry tables; it does not fully validate unrelated TOML syntax.

Start a new shell and reopen apps after setup. A user LaunchAgent applies the managed privacy environment to GUI launches at login. An app already running, or started before the login job, can retain its old environment. Explicit flags, managed policy, local project configuration, remote servers, and extensions can have separate behavior.

## Automatic controls

The environment values are in [env.sh](../home/.config/telemetry/env.sh). The exact scope and all source links are in [telemetry-audit.json](telemetry-audit.json). These controls do not disable service requests or update checks.

| Tool | Setup action | Evidence |
| --- | --- | --- |
| bun | `DO_NOT_TRACK=1` | [Official source](https://bun.sh/docs/runtime/environment-variables) |
| cargo-binstall | `BINSTALL_DISABLE_TELEMETRY=true` | [Official source](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md) |
| chatgpt | Shared Codex local-runtime analytics and OTel settings in $CODEX_HOME/config.toml (default ~/.codex/config.toml). Does not establish a native crash-report or account-training opt-out. | [Official source](https://learn.chatgpt.com/docs/config-file/config-advanced) |
| claude-code | `DISABLE_TELEMETRY=1`, `DISABLE_ERROR_REPORTING=1`, `CLAUDE_CODE_ENABLE_TELEMETRY=0`, `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`; Merge telemetry environment values into $CLAUDE_CONFIG_DIR/settings.json (default ~/.claude/settings.json). | [Official source](https://code.claude.com/docs/en/data-usage#telemetry-services) |
| cocoapods | `COCOAPODS_DISABLE_STATS=true` | [Official source](https://blog.cocoapods.org/Stats/) |
| codex | analytics.enabled=false; OTel exporter, metrics_exporter and trace_exporter=none; log_user_prompt=false in $CODEX_HOME/config.toml. Standard tables are merged; ambiguous inline/dotted forms fail without changes. | [Official source](https://learn.chatgpt.com/docs/config-file/config-advanced#metrics) |
| cursor | telemetry.telemetryLevel=off in Cursor User/settings.json; enable-crash-reporter=false in ~/.cursor/argv.json. Merge only these inherited controls, preserving JSONC comments and unrelated values. Cursor-specific telemetry is not established as fully disabled. | [Official source](https://forum.cursor.com/t/critical-terminal-sandbox-fails-on-orbstack-vms-breaking-agent-and-remote-ssh-workflow/167586/13) |
| docker-cli | Unset `DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT` | [Official source](https://docs.docker.com/engine/cli/otel/) |
| flyctl | `FLY_SEND_METRICS=false`; Saved preference: `flyctl settings analytics disable` | [Official source](https://fly.io/docs/flyctl/settings-analytics-disable/) |
| gcloud | `CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true`; Saved preference: `gcloud config set core/disable_usage_reporting true` | [Official source](https://docs.cloud.google.com/sdk/docs/usage-statistics) |
| gem:fastlane | `FASTLANE_OPT_OUT_USAGE=YES` | [Official source](https://docs.fastlane.tools/index.html#metrics) |
| gh | `GH_TELEMETRY=false`; Saved preference: `gh config set telemetry disabled`; After successful login and API checks in auth-setup. | [Official source](https://docs.github.com/en/github-cli/github-cli/github-cli-telemetry) |
| github:entireio/cli | `ENTIRE_TELEMETRY_OPTOUT=1` | [Official source](https://github.com/entireio/cli/blob/main/docs/security-and-privacy.md) |
| homebrew | `HOMEBREW_NO_ANALYTICS=1`; Saved preference: `brew analytics off` | [Official source](https://docs.brew.sh/Analytics) |
| hunk | `DO_NOT_TRACK=1`; Installer aggregate release reporting only; CLI collection remains unverified. | [Official source](https://github.com/modem-dev/hunk) |
| mise | `MISE_USE_VERSIONS_HOST_TRACK=false`, `MISE_OTEL_ENABLED=false`, `MISE_OTEL_LOGS=false`; use_versions_host_track=false in tracked global mise configuration. | [Official source](https://mise.jdx.dev/configuration/settings.html#use_versions_host_track) |
| npm:cf | `CF_SEND_TELEMETRY=false`, `DO_NOT_TRACK=1` | [Official source](https://developers.cloudflare.com/cf/environment-variables/) |
| npm:ctx7 | `CTX7_TELEMETRY_DISABLED=1` | [Official source](https://github.com/upstash/context7/blob/master/packages/cli/README.md) |
| npm:eas-cli | `DISABLE_EAS_ANALYTICS=1`; Saved preference: `eas analytics off` | [Official source](https://github.com/expo/eas-cli) |
| pi-coding-agent | `PI_TELEMETRY=0` | [Official source](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/environment-variables.md) |
| skills | `DISABLE_TELEMETRY=1`, `DO_NOT_TRACK=1` | [Official source](https://github.com/vercel-labs/skills/blob/main/README.md) |
| t3-cli | `T3CODE_TELEMETRY_ENABLED=false`, `T3CODE_OTEL_SDK_DISABLED=true` | [Official source](https://github.com/pingdotgg/t3code/blob/main/apps/server/src/telemetry/AnalyticsService.ts) |
| t3-code@nightly | `T3CODE_TELEMETRY_ENABLED=false`, `T3CODE_OTEL_SDK_DISABLED=true` | [Official source](https://raw.githubusercontent.com/pingdotgg/t3code/main/apps/server/src/telemetry/AnalyticsService.ts) |
| turbo | `TURBO_TELEMETRY_DISABLED=1`; Saved preference: `turbo telemetry disable`; Anonymous analytics. Experimental OTLP opt-out is per enabled project: setting TURBO_EXPERIMENTAL_OTEL_ENABLED globally can require the experimentalObservability future flag. It is not exported by dotfiles. | [Official source](https://turborepo.dev/docs/telemetry) |
| vercel | `VERCEL_TELEMETRY_DISABLED=1`; Saved preference: `vercel telemetry disable` | [Official source](https://vercel.com/docs/cli/about-telemetry) |
| wrangler | `WRANGLER_SEND_METRICS=false`, `WRANGLER_SEND_ERROR_REPORTS=false`; Saved preference: `wrangler telemetry disable`; CLI usage and error reports. Deployment dependency metadata needs dependencies_instrumentation.enabled=false in each project; dotfiles does not own those files. | [Official source](https://developers.cloudflare.com/workers/wrangler/system-environment-variables/) |
| zulu@17 | `AZ_CRS_ARGUMENTS=enable=false`; Merge the enable=false property into existing comma-separated AZ_CRS_ARGUMENTS, preserving other properties. Built-in Connected Runtime Service only; explicit JVM mode flags override it. Newer Zulu PSU builds omit CRS; this does not cover a separately installed Intelligence Cloud Agent. | [Official source](https://docs.azul.com/intelligence-cloud/setup-jvm/using-zulu-zing) |

The Claude Code analytics opt-out also stops feature-flag requests; some gated features can be affected. The Vercel `skills` opt-out also stops security-audit API lookups. Manual feedback submissions remain available. Cursor settings cover inherited telemetry and crash controls; a complete Cursor-specific opt-out is not established.

## Manual settings

No supported script interface was established for these controls. Apply them in the app or account so other preferences remain intact.

| Tool | Action and limit | Evidence |
| --- | --- | --- |
| Chrome | Settings > You and Google > Google services: turn off “Help improve Chrome’s features and performance.” The managed MetricsReportingEnabled policy is not established for an unmanaged Mac. | [Official source](https://support.google.com/chrome/answer/14746339?hl=en) |
| Warp | Settings > Privacy: turn off “Help improve Warp” and “Send crash reports.” Availability can depend on the plan or team policy. | [Official source](https://docs.warp.dev/support-and-community/privacy-and-security/privacy) |
| Android Studio | Settings > Appearance & Behavior > Data Sharing: turn off usage sharing. Older releases put Data Sharing under System Settings. | [Official source](https://developer.android.com/studio/gemini/data-and-privacy) |
| Transporter / macOS | System Settings > Privacy & Security > Analytics & Improvements: turn off “Share Mac Analytics” and “Share with app developers.” No app-specific switch was verified. | [Official source](https://support.apple.com/en-hk/guide/mac-help/mh27990/mac) |
| Xcode / macOS | System Settings > Privacy & Security > Analytics & Improvements: turn off “Share Mac Analytics” and “Share with app developers.” These are system controls. | [Official source](https://support.apple.com/en-za/guide/mac-help/mh27990/26/mac/26) |
| Discord | User Settings > Data & Privacy: turn off “Use Data to Improve Discord.” This limits analytics use; Discord states that signals can still be transmitted. | [Official source](https://support.discord.com/hc/en-us/articles/21864805694999-Data-Used-to-Improve-Discord) |
| Zoom | Web portal > Data & Privacy > Diagnostic Data Preferences: turn off “Optional Diagnostic Data.” Required diagnostics remain. | [Official source](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0057779) |
| OBS | In a crash dialog, leave the crash-upload consent checkbox unchecked. Current source requires consent for each upload; no persistent switch was established. | [Official source](https://raw.githubusercontent.com/obsproject/obs-studio/master/frontend/OBSApp.cpp) |
| Cursor account / CLI | Turn account Privacy Mode on in Cursor Settings > General > Privacy Mode, or use the team dashboard. This controls training/retention and is separate from general analytics. | [Official source](https://prod.cursor.com/help/security-and-privacy/privacy) |

Wrangler deployment dependency metadata has a separate project control: set `dependencies_instrumentation.enabled=false` in each project’s Wrangler configuration. This can remove dependency analytics and related supply-chain insights. Dotfiles does not change project files. [Cloudflare documentation](https://developers.cloudflare.com/workers/wrangler/configuration/).

Turborepo’s optional experimental OTLP exporter can be disabled with `experimentalObservability.otel.enabled=false`, or `TURBO_EXPERIMENTAL_OTEL_ENABLED=0`, in a project that enables the observability future flag. Dotfiles does not export this experimental variable globally because configuring observability can require that project flag. [Turborepo documentation](https://github.com/vercel/turborepo/blob/main/apps/docs/content/docs/reference/configuration.mdx).

## Limits and unverified controls

`none_found` means a bounded official-documentation/source review found no supported opt-out. It does not prove that a tool collects no data. The complete inventory, including tools without a control, is in [telemetry-audit.json](telemetry-audit.json).

| Tool | Result | Evidence |
| --- | --- | --- |
| npm:sfw | Free edition telemetry cannot be disabled. | [Official source](https://docs.socket.dev/docs/socket-firewall-free) |
| cloudflared | No documented supported control for automatic Sentry error reporting was found. | [Official source](https://raw.githubusercontent.com/cloudflare/cloudflared/master/cmd/cloudflared/main.go) |
| infisical | The advertised --telemetry=false flag is unverified: source initializes the client before normal flag parsing. No persistent control was established. | [Official source](https://github.com/Infisical/cli/blob/main/packages/cmd/root.go) |
| hunk | Only installer release-discovery reporting was verified; the CLI binary remains unverified. | [Official source](https://github.com/modem-dev/hunk) |
| TestFlight | Beta-app crash and usage reports cannot be opted out while testing. Device analytics switches do not override this. | [Official source](https://www.apple.com/legal/internet-services/itunes/testflight/) |
| tailscale-app | The daemon --no-logs-no-support option does not apply to the macOS GUI app. | [Official source](https://tailscale.com/docs/features/logging?tab=macos) |
| notion-calendar | General Notion docs mention a support-based analytics opt-out, but Calendar-specific scope and crash reporting remain unverified. No automatic setting was established. | [Official source](https://www.notion.com/help/notion-calendar-security-practices) |
| helium-browser | Crash reporting requires explicit consent. Decline it; no exact persistent key was verified. The official site states there is no browser analytics. | [Official source](https://helium.computer/privacy) |
| superwhisper | Official release notes describe optional error/performance reporting. Leave it disabled in app settings; the current exact key and UI label were not established. | [Official source](https://superwhisper.com/changelog) |
| davinci-resolve | Official manual access failed. No exact supported preference was established. | [Official source](https://www.blackmagicdesign.com/privacy) |
| github:CoastalFuturist/bodhi | The exact upstream repository was unavailable. No verified telemetry control was established. | [Official source](https://github.com/CoastalFuturist/bodhi) |
| github:flowcopilot/aether | The exact upstream repository was unavailable. No verified control was established. | [Official source](https://github.com/flowcopilot/aether) |

Each entry had a separate tool research assignment. Agent thread limits required reuse: 14 fresh tool agents, 137 focused assignments to reused workers, and 44 individual dispatcher audits. A separate agent reviewed the implementation.

The audit includes the managed shell/tmux plugins. It excludes project dependencies, other plugins, the separate nvim repository dependencies, and tools outside the tracked inventories. Tests use fake commands and isolated settings. No fresh-Mac installation or network capture was performed.
