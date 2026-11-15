---
name: react-native
description: Load this skill before you read or change code in a project whose package.json lists react-native. Covers crashes, slow screens and long lists, animations and gestures with Reanimated or Gesture Handler, native modules, navigation, and upgrades.
license: MIT
metadata:
  author: flowcopilot
  upstream: software-mansion-labs/skills@58afa0a09b01dc47819af8fd48bb062561414108
  upstream_callstack: "callstackincubator/agent-skills@59e9d17446a248b21d86f078fcd0bd2d36db1ca4"
---

<!-- Modified by Flow Copilot from software-mansion-labs/skills. -->

# React Native

Use the target project's installed versions and the user's task to select references. Read only the relevant workflow and its supporting files.

## Choose a source

- For animations, gestures, audio, on-device AI, rich text, JSI, and worklets, start with [Software Mansion's best practices](references/software-mansion/react-native-best-practices/index.md).
- For profiling, rendering, startup time, memory, and bundle size, start with [Callstack's best practices](references/callstack/react-native-best-practices/index.md).
- For navigation, upgrades, TV, library creation, CI, or migration, select the matching Callstack workflow below.
- For Software Mansion libraries and tools, select the matching Software Mansion workflow below. These workflows can also cover web or native platforms; apply only the parts relevant to the task.

Both upstream skills named react-native-best-practices are preserved. Their source directories prevent filename collisions. A request to read an upstream skill means its index.md reference in the same source directory. Relative paths remain relative to the imported file. When advice overlaps, use the guidance that matches the installed library and version; resolve conflicting claims against current official documentation.

This bundle imports the skills directories of both repositories, including nested skills. Plugin configuration and externally hosted skills linked by upstream READMEs are not included.

## Software Mansion

- [detour-onboarding](references/software-mansion/detour/detour-onboarding/index.md): Complete onboarding guide for developers who are new to Detour, the open-source deferred deep linking SDK by Software Mansion.
- [migrate-to-detour](references/software-mansion/detour/migrate-to-detour/index.md): Use when the user mentions migrating deep links, switching away from Branch or AppsFlyer, replacing their deep linking SDK, setting up Detour deep linking for the first time, or asks how Branch/AppsFlyer concepts map to Detour.
- [expo-horizon](references/software-mansion/expo-horizon/index.md): Software Mansion's guide for migrating Expo SDK apps to Meta Quest using expo-horizon packages.
- [fishjam](references/software-mansion/fishjam/index.md): Software Mansion's Fishjam — hosted WebRTC platform for video, audio, one-to-many livestreaming, and compositions.
- [fishjam-composition](references/software-mansion/fishjam/references/composition/index.md): Fishjam compositions: server-side, real-time mixing of several live streams (room peers, WHIP, RTMP, MP4) into new output streams with layouts, overlays, captions, and audio mixes, built on Smelter.
- [fishjam-js-server-sdk](references/software-mansion/fishjam/references/js-server-sdk/index.md): Node.js / TypeScript server SDK for Fishjam — backends that create rooms, mint peer tokens, listen to server notifications, and run agents.
- [fishjam-platform](references/software-mansion/fishjam/references/platform/index.md): Fishjam platform fundamentals — domain model and auth shared by all SDKs.
- [fishjam-python-server-sdk](references/software-mansion/fishjam/references/python-server-sdk/index.md): Python server SDK for Fishjam — backends that create rooms, mint peer tokens, receive server notifications, and run voice agents.
- [fishjam-react-client](references/software-mansion/fishjam/references/react-client/index.md): Browser-only React SDK for Fishjam — joining rooms, capturing camera/microphone/screen, displaying peers, and acting as a livestream streamer or viewer in a React web app.
- [fishjam-react-native-client](references/software-mansion/fishjam/references/react-native-client/index.md): React Native / Expo SDK for Fishjam — video/audio streaming on iOS and Android.
- [moq-kit](references/software-mansion/moq-kit/index.md): Software Mansion's moq-kit — native Swift (iOS) and Kotlin (Android) SDKs for Media over QUIC (moq-lite) live streaming: sub-second-latency playback, camera/microphone/screen publishing, and realtime data tracks over a MoQ relay.
- [pulsar-haptics](references/software-mansion/pulsar-haptics/index.md): Implement, migrate, design, review, and troubleshoot haptic feedback with Software Mansion Pulsar across React Native, iOS, Android, Kotlin Multiplatform, Flutter, and Web.
- [radon-mcp](references/software-mansion/radon-mcp/index.md): Best practices for using Radon IDE's MCP tools when developing, debugging, and inspecting React Native and Expo apps.
- [react-native-best-practices](references/software-mansion/react-native-best-practices/index.md): Software Mansion's best practices for production React Native and Expo apps on the New Architecture.
- [animations](references/software-mansion/react-native-best-practices/references/animations/index.md): Production animation patterns for React Native using Reanimated 4, Skia, WebGPU, and TypeGPU.
- [audio](references/software-mansion/react-native-best-practices/references/audio/index.md): Software Mansion's best practices for audio in React Native using react-native-audio-api.
- [enable-worklets-bundle-mode](references/software-mansion/react-native-best-practices/references/enable-worklets-bundle-mode/index.md): Enable react-native-worklets Bundle Mode (imports inside worklets, third party libraries on worklet runtimes) in an Expo, RN CLI or brownfield React Native app, including the mandatory metro/metro-runtime patches.
- [gestures](references/software-mansion/react-native-best-practices/references/gestures/index.md): Software Mansion's best practices for gestures in React Native apps using React Native Gesture Handler.
- [jsi](references/software-mansion/react-native-best-practices/references/jsi/index.md): React Native JSI (JavaScript Interface) — C++ API for interacting with the JS runtime.
- [multithreading](references/software-mansion/react-native-best-practices/references/multithreading/index.md): Software Mansion's best practices for multithreading in React Native apps using react-native-worklets.
- [on-device-ai](references/software-mansion/react-native-best-practices/references/on-device-ai/index.md): Build on-device AI features in React Native and Expo apps with React Native ExecuTorch.
- [rich-text](references/software-mansion/react-native-best-practices/references/rich-text/index.md): Software Mansion's best practices for rich text in React Native using react-native-enriched-html (formerly react-native-enriched) and react-native-enriched-markdown.
- [svg](references/software-mansion/react-native-best-practices/references/svg/index.md): Software Mansion's best practices for SVG rendering in React Native apps using React Native SVG.
- [react-native-moq](references/software-mansion/react-native-moq/index.md): Software Mansion's react-native-moq — Media over QUIC (MoQ) live streaming for React Native: sub-second-latency video/audio playback, camera/mic/screen publishing, and realtime data tracks over a MoQ relay.
- [rnrepo](references/software-mansion/rnrepo/index.md): Best practices for integrating and using RNRepo — Software Mansion's infrastructure for pre-built React Native library artifacts that reduces native build times by up to 2×.
- [typegpu](references/software-mansion/typegpu/index.md): TypeGPU is type-safe WebGPU in TypeScript.

## Callstack

- [assess-react-native-migration](references/callstack/assess-react-native-migration/index.md): Assesses whether and how an existing mobile product should migrate to React Native.
- [create-react-native-library](references/callstack/create-react-native-library/index.md): Scaffolds React Native libraries with create-react-native-library for standalone libraries or local native modules and views.
- [github-actions](references/callstack/github-actions/index.md): GitHub Actions workflow patterns for React Native iOS simulator and Android emulator cloud builds with downloadable artifacts.
- [react-native-best-practices](references/callstack/react-native-best-practices/index.md): Provides React Native performance optimization guidelines for FPS, TTI, bundle size, memory leaks, re-renders, and animations.
- [react-native-brownfield-migration](references/callstack/react-native-brownfield-migration/index.md): Implements an accepted incremental brownfield migration from native iOS or Android to React Native or Expo using @callstack/react-native-brownfield.
- [react-native-tv-best-practices](references/callstack/react-native-tv-best-practices/index.md): Reviews React Native TV apps for focus/D-pad navigation, 10-foot UI layout, TV playback/DRM integration, low-memory TV performance, and TV accessibility.
- [react-navigation](references/callstack/react-navigation/index.md): Provides React Navigation UI patterns for stacks, tabs, drawers etc.
- [upgrading-react-native](references/callstack/upgrading-react-native/index.md): Upgrades React Native apps to newer versions by applying rn-diff-purge template diffs, updating package.json dependencies, migrating native iOS and Android configuration, resolving CocoaPods and Gradle changes, and handling breaking API updates.
- [writing-user-docs](references/callstack/writing-user-docs/index.md): House style for user-facing documentation — voice, scope, structure, and what to leave out.
