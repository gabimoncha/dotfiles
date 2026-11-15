<!-- Modified by Flow Copilot from callstack/agent-device. -->

# iOS Simulator

Require the `agent-device` CLI to be installed separately before driving a simulator:

```bash
npm install -g agent-device@latest
```

Treat installation and upgrades as user-owned setup steps. Do not run that command autonomously or substitute a mutable `npx -y agent-device@latest` invocation.

For a normal app-driving task, start immediately. Do not probe first with `--help`, `--version`, `devices`, `appstate`, `snapshot`, or `screenshot`. Target iOS explicitly when opening an app or bundle id:

```bash
agent-device open <app-or-bundle-id> --platform ios --foreground
```

Follow the initial interactive snapshot and corrective error hints. If the shell reports that `agent-device` is unavailable, stop and ask the user to install it or expose their existing installation on `PATH`.

Only when the task is specialized or a command shape is unclear, read the relevant version-matched help topic:

```bash
agent-device help validate        # engineering validation and build freshness
agent-device help debugging       # screenshots, logs, traces, video, and failures
agent-device help react-native    # React Native and Expo runtime guidance
agent-device help react-devtools  # React components, props/state/hooks, render profiling
agent-device help scripting       # durable replay and CI workflows
```
