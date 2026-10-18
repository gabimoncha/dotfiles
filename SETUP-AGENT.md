# Setup repair guide

Scripts do the setup. Use this guide when `./bin/setup` reports a failed,
blocked, or deferred stage, or when the user asks you to repair one. A repair
is done when the stage's script exits 0 and a rerun of setup reports the stage
as completed.

## Rules for every repair

- Repair with the scripts in `bin/`. Write a one-off command only for a step
  that no script covers, and tell the user which step that was.
- If a command needs `sudo` and `sudo -n true` fails, ask the user to run
  `./bin/sudo-grant --enable` in their own terminal. After that, your shell can
  use `sudo` until 30 minutes pass without a `sudo` command. Run
  `./bin/sudo-grant --disable` when you finish.
- The user types each password into the prompt that asks for it. Keep
  credentials out of commands, files, logs, and your replies.
- Use only public releases of macOS, Xcode, iOS, and simulator runtimes. If
  `./bin/preflight` reports a macOS update or a prerelease, stop. Tell the user
  to update in **System Settings > General > Software Update**, restart if
  needed, and rerun `./bin/setup`.
- Ask the user before you delete an app, a simulator runtime, or user data.
- Run commands from the repository root as the normal user.
- If a step fails twice with the same error, stop. Report the command, the
  error, and your best guess at the cause.

## Find the failed stage

1. Open `summary.txt` in the newest `.local/setup-runs/<run-id>/` directory.
   Each line has the outcome, the stage, the reason, the log file, and the
   repair hint.
2. Repair the first failed stage first. A later stage can be blocked only
   because an earlier stage failed.
3. Read the stage log. Find the script for the stage in the table below, and
   rerun that script.
4. When the scripts for all failed stages exit 0, run
   `./bin/setup --continue`. The setup reuses finished work.

| Stage | Script |
| --- | --- |
| `preflight` | `./bin/preflight` |
| `touch_id` | `./bin/configure-sudo-touch-id --enable` |
| `sudo_grant` | `./bin/sudo-grant --enable` (the user runs it in a terminal) |
| `mise` | `./bin/ensure-mise-standalone --skip-update` |
| `install_gh` | `./bin/github-bootstrap install-gh` |
| `authenticate_api` | `./bin/auth-setup --api-only` |
| `authenticate_ssh` | `./bin/auth-setup --ssh-only` |
| `verify_mise_access` | `./bin/auth-setup --verify-mise` |
| `links_before_packages`, `service_links`, `final_links` | `./bin/link-dotfiles` |
| `manifest_apps` | `./bin/install-apps` |
| `capabilities` | `./bin/check-mise-tools` |
| `standalone_agents` | `./bin/ensure-harnesses-standalone` |
| `telemetry_foundations`, `telemetry` | `./bin/configure-telemetry` |
| `app_settings` | `./bin/configure-app-settings` |
| `screenshots` | `./bin/configure-screenshots` |
| `finder` | `./bin/finder-sidebar-favorites` |
| `mobile_setup` | `./bin/install-mobile-dev` |

The other stages run functions in `bin/bootstrap`. To retry one of them, repair
the cause from its log, then run `./bin/setup --continue`.

## Mobile development

The stage is `mobile_setup`. The repair is done when
`./bin/check-mobile-ready` exits 0.

Run `./bin/install-mobile-dev`. It skips finished steps. Then use the first
error in its output:

- **The App Store did not install Xcode.** Ask the user to open the App Store
  app, sign in, and confirm that Xcode shows **Get** or **Open**. Then rerun the
  script. If the App Store cannot install Xcode, ask the user to download the
  public `.xip` from https://developer.apple.com/download/all/ in a browser, and
  give the user this command:
  `xcodes install <public-version> --path "/path/to/Xcode.xip" --select --experimental-unxip`.
- **A `sudo` command fails.** Follow the `sudo` rule above.
- **The Xcode is a prerelease, or its build is unknown.** List
  `/Applications/Xcode*.app`. Ask the user which public Xcode to keep and
  select.
- **iOS platform support fails to install.** Ask the user to install iOS in
  **Xcode > Settings > Components**.
- **A Homebrew step fails.** Run `brew doctor`, repair what it reports, and
  rerun the script.
- **A `sudo` step fails after a long Xcode download.** The script keeps the
  `sudo` timestamp valid only if `sudo -n true` worked when it started. Ask the
  user to run `./bin/sudo-grant --enable`, then rerun the script.

When the check passes, tell the user to finish these steps in Android Studio:
install SDK Platform 35, Sources for Android 35, Android SDK Build-Tools, and
Android Emulator, and create a virtual device.
