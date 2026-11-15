---
name: agent-surf
description: Load this skill before you drive a browser, an iOS or Android device, a simulator or emulator, or a desktop app, or write a shell script that drives one, or when package.json or the task names agent-browser, agent-device, or agent-desktop. Covers web automation, screenshots and scraping, Electron apps and Slack, mobile and TV apps, exploratory QA, and native desktop apps on macOS, Windows, and Linux. Do not load it for Playwright, Cypress, Detox, or XCUITest test files.
license: Apache-2.0 AND MIT
metadata:
  author: flowcopilot
  upstream: vercel-labs/agent-browser@5868f7c05020e047c00e68e4abf9253cce864f41
  upstream_agent_device: "callstack/agent-device@ff8c2285c808135b592e77f53ae3ce28d31786b8"
  upstream_agent_desktop: "vercel-labs/agent-desktop@5261b5287b5208e7c4bf3713df6f66faaaf2c4cc"
---

<!-- Modified by Flow Copilot from vercel-labs/agent-browser. -->

# Agent Surf

Three CLIs let an agent act on a live interface. Each one reads the interface as an accessibility tree with short element refs, then clicks, types, and scrolls by ref. Choose the CLI by the surface that the task acts on. Read only the matching reference and its supporting files.

All paths in this file are relative to the folder that contains this SKILL.md. For example, `references/agent-browser/core/index.md` is `<skills folder>/agent-surf/references/agent-browser/core/index.md`.

## Choose a CLI

- Web pages, web apps, and cloud browsers: agent-browser. Start with [core](references/agent-browser/core/index.md).
- iPhone, iPad, and Android devices, iOS Simulator, Android Emulator, and TV apps: agent-device. Start with [agent-device](references/agent-device/agent-device/index.md).
- Native desktop apps and system surfaces such as menus, the menu bar, the tray, and notifications on macOS, Windows, or Linux: agent-desktop. Start with [agent-desktop](references/agent-desktop/agent-desktop/index.md), then read the guide for the operating system.
- Electron apps such as VS Code, Slack, Discord, or Notion: use the agent-browser [electron](references/agent-browser/electron/index.md) workflow, which connects over the Chrome DevTools Protocol. Use agent-desktop when the task also touches native windows or system surfaces.
- Exploratory QA or a bug hunt: use the agent-browser [dogfood](references/agent-browser/dogfood/index.md) workflow for a web app, and the agent-device [dogfood](references/agent-device/dogfood/index.md) workflow for a mobile app.

## Installed versions

Read the bundled reference before the first command. It works when the CLI is not installed. The references are a snapshot of each upstream revision, and the installed CLI can be newer. When a command or flag from a reference fails, run the matching `skills get` command. It prints the guide for the installed version. An upstream guide that says to run `skills get` means the bundled file below:

- `agent-browser skills get <name>`: `references/agent-browser/<name>/index.md`. For example, `agent-browser skills get core` is [core](references/agent-browser/core/index.md).
- `agent-desktop skills get desktop`: [agent-desktop](references/agent-desktop/agent-desktop/index.md). Its named references are [commands-interaction](references/agent-desktop/agent-desktop/references/commands-interaction.md), [commands-observation](references/agent-desktop/agent-desktop/references/commands-observation.md), [commands-system](references/agent-desktop/agent-desktop/references/commands-system.md), [workflows](references/agent-desktop/agent-desktop/references/workflows.md).
- `agent-desktop skills get platform`: the guide for the current operating system, `references/agent-desktop/agent-desktop-<os>/index.md`, where `<os>` is `macos`, `windows`, or `linux`.
- `agent-desktop skills get <skill> <path>`: `references/agent-desktop/<skill>/<path>`.

For agent-device, run `agent-device help <topic>` when a command shape is unclear.

The slack workflow does not link its supporting files. Use [slack-tasks](references/agent-browser/slack/references/slack-tasks.md) for task recipes and the [report template](references/agent-browser/slack/templates/slack-report-template.md) for a written summary.

Use [jev-desktop](references/agent-desktop/jev-desktop/index.md) only when the user has a clone of the agent-desktop repository and a `TYPESAFE_API_KEY`.

An upstream skill name, such as `core` or `ios-simulator`, means its index.md reference in the same source directory. Both agent-browser and agent-device have a `dogfood` skill. Use the one for the surface under test. Relative paths stay relative to the imported file.

This bundle imports `skill-data/` from agent-browser and `skills/` from agent-device and agent-desktop. The agent-browser discovery stub, plugin metadata, and agent UI metadata are not included.

## agent-browser

- [agentcore](references/agent-browser/agentcore/index.md): Run agent-browser on AWS Bedrock AgentCore cloud browsers.
- [core](references/agent-browser/core/index.md): Core agent-browser usage guide.
- [derive-client](references/agent-browser/derive-client/index.md): Reverse-engineer a website's internal API by recording browser traffic into a HAR file, then generate a standalone client or CLI that calls the endpoints directly, with no browser needed after the first recording.
- [dogfood](references/agent-browser/dogfood/index.md): Systematically explore and test a web application to find bugs, UX issues, and other problems.
- [electron](references/agent-browser/electron/index.md): Automate Electron desktop apps (VS Code, Slack, Discord, Figma, Notion, Spotify, etc.) using agent-browser via Chrome DevTools Protocol.
- [protected-vercel-deployments](references/agent-browser/protected-vercel-deployments/index.md): Access and test Vercel deployments protected by Vercel Authentication, SSO, or Deployment Protection with agent-browser.
- [slack](references/agent-browser/slack/index.md): Interact with Slack workspaces using browser automation.
- [vercel-sandbox](references/agent-browser/vercel-sandbox/index.md): Run agent-browser + Chrome inside Vercel Sandbox microVMs for browser automation from any Vercel-deployed app.
- [webmcp-gen](references/agent-browser/webmcp-gen/index.md): Build and validate experimental WebMCP tools for an existing web page.

## agent-device

- [agent-device](references/agent-device/agent-device/index.md): Automates Apple-platform apps (iOS, tvOS, macOS), Android devices (including Android TV and Fire TV on Fire OS), and Amazon Vega OS TV apps in Vega Virtual Devices.
- [android-emulator](references/agent-device/android-emulator/index.md): Verify and debug native, React Native, Expo, or Flutter apps on an Android Emulator with agent-device.
- [dogfood](references/agent-device/dogfood/index.md): Systematically explore and test a mobile app on iOS/Android with agent-device to find bugs, UX issues, and other problems.
- [ios-simulator](references/agent-device/ios-simulator/index.md): Verify and debug native, React Native, Expo, or Flutter apps on an iOS Simulator with agent-device.

## agent-desktop

- [agent-desktop-ffi](references/agent-desktop/agent-desktop-ffi/index.md): C-ABI bindings over agent-desktop's PlatformAdapter.
- [agent-desktop-linux](references/agent-desktop/agent-desktop-linux/index.md): Linux platform guide for the agent-desktop CLI.
- [agent-desktop-macos](references/agent-desktop/agent-desktop-macos/index.md): macOS platform guide for the agent-desktop CLI.
- [agent-desktop-windows](references/agent-desktop/agent-desktop-windows/index.md): Windows platform guide for the agent-desktop CLI.
- [agent-desktop](references/agent-desktop/agent-desktop/index.md): Operate desktop applications on macOS, Windows and Linux through native accessibility trees, using the agent-desktop CLI.
- [jev-desktop](references/agent-desktop/jev-desktop/index.md): Drive a desktop application from one plain-language goal, or resolve one intent at a time, without ever reading the accessibility tree.
