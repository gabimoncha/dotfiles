# Setup repair guide

Scripts do the setup. Use this guide when `./bin/setup` reports a failed,
blocked, or deferred step, or when the user asks you to repair one. A repair
is done when the step's script exits 0 and a rerun of setup reports the step
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

## Find the failed step

Setup keeps the latest three runs under `.local/setup-runs/`. Copy the failed
run outside that directory before repeated repair attempts if you need its logs.

1. Open `summary.txt` in the newest `.local/setup-runs/<run-id>/` directory.
   Each line has the outcome, the step, the reason, the log file, and the
   repair hint.
2. Repair the first failed step. A required step stops the run, and setup
   records the later steps as blocked. A step marked `--optional` in
   `bin/setup` records its failure without stopping the run.
3. Read the step's output in `setup.log` in the same folder. Each line starts
   with the step name in brackets. A step that asks for a password or a login
   prints to the terminal only. Find the script for the step in the table
   below, and rerun that script.
4. When the scripts for all failed steps exit 0, run
   `./bin/setup --continue`. The setup reuses finished work.

| Step | Script |
| --- | --- |
| `preflight` | `./bin/preflight` |
| `touch_id` | `./bin/configure-sudo-touch-id --enable` |
| `sudo_grant` | `./bin/sudo-grant --enable` (the user runs it in a terminal) |
| `mise` | `./bin/install-standalone mise` |
| `install_gh` | `./bin/github-bootstrap install-gh` |
| `authenticate_api` | `./bin/auth-setup --api-only` |
| `authenticate_ssh` | `./bin/auth-setup --ssh-only` |
| `configure_git` (Linux) | `./bin/auth-setup --git-only` |
| `verify_mise_access` | `./bin/auth-setup --verify-mise` |
| `links`, `final_links` | `./bin/link-dotfiles` |
| `shell` | `./bin/setup --continue` reruns it. Check with `./bin/repo-mise bootstrap repos status`. For a `conflict`, ask the user before you move the path aside. |
| `defaults` | `./macos/defaults.sh` |
| `manifest_apps` | `./bin/install-apps` |
| `mise_inventory` | `./bin/repo-mise --global install`, then `./bin/check-mise-tools` |
| `standalone_agents` | `./bin/install-standalone` (`--first-only` in the first phase) |
| `system_packages` (Linux) | `./bin/repo-mise bootstrap --only packages,user --yes`; check with `bootstrap packages status` |
| Linux prerequisites | `./bin/linux-prerequisites` (bin/setup runs it before the runtime starts) |
| `telemetry` | `./bin/configure-telemetry` |
| `app_settings` | `./bin/configure-app-settings` |
| `screenshots` | `./bin/configure-screenshots` |
| `finder` | `./bin/finder-sidebar-favorites` |
| `mobile_setup` | `./bin/install-mobile-dev` |

The other steps run functions in `bin/lib/setup-steps.sh`. To retry one of
them, repair the cause from its output, then run `./bin/setup --continue`.

## Mobile development

The step is `mobile_setup`. The repair is done when
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
- **`~/.androidrc` does not turn off Android CLI metrics.** Run
  `./bin/link-dotfiles`, then rerun the script.
- **sdkmanager needs Java.** Install the `zulu@17` cask from the Brewfile, then
  rerun the script.
- **The Command Line Tools download fails, or its SHA-256 differs.** Check the
  network and rerun. If Google replaced the file, find the new build in
  https://dl.google.com/android/repository/repository2-3.xml, compare its SHA-1
  with the download, and ask the user before you change the pin in
  `bin/install-mobile-dev`.
- **An Android SDK package fails to install.** Rerun the script. It installs
  only the missing packages from `apps/android-sdk.txt`.
- **adb on PATH is not the SDK copy.** Another install, such as the
  `android-platform-tools` cask, is ahead on PATH. Ask the user before you
  remove it. Keep `ANDROID_HOME` as the only SDK.

To change an Android SDK version, edit `apps/android-sdk.txt`. Take the versions
from the app's generated Gradle files, or from React Native's
`gradle/libs.versions.toml` (`compileSdk`, `buildTools`, `ndkVersion`). Do not
install Android SDK packages with Homebrew. An emulator is optional: install
`emulator` and a system image with `sdkmanager`, or in Android Studio.
