---
name: expo
description: Load this skill before you read or change code in a project whose package.json lists expo, or when the task names Expo or EAS. Covers routes and navigation, data fetching, native UI, native modules, SDK upgrades, EAS builds, hosting, and OTA updates.
license: MIT
metadata:
  author: flowcopilot
  upstream: expo/skills@8a0dc4fa57ae345923c357e1451cbcd8b6f2a7db
---

<!-- Modified by Flow Copilot from expo/skills. -->

# Expo

Read [expo-overview](references/expo-overview.md) for shared setup rules, then load the references that match the user's goal. Expo documentation and the installed Expo and EAS CLIs are the source of truth.

Former Expo and EAS skill names refer to the workflow files below. Load those references when an imported instruction asks for another skill or its SKILL.md. Paths in workflow references are relative to that reference; `<skill-root>` means this combined expo directory. The upstream overview mentions expo-tailwind-setup, which is not present in this source collection; consult current Expo documentation for that topic.

This package contains skill instructions and helper scripts. Plugin MCP configuration and telemetry hooks are not installed by this package.

## Start Here

Load this first for any Expo/EAS task, then route to the specific skill below.

| Skill | Use it for |
| --- | --- |
| [expo-overview](references/expo-overview.md) | Router and shared setup rules; the entry point when a request is vague or the user hasn't named a specific Expo tool. |

## Framework (open source)

Free, open-source Expo SDK and React Native skills.

| Skill | Use it for |
| --- | --- |
| [expo-project-structure](references/expo-project-structure.md) | Folder structure for a new Expo app: `src/` layout, routes-only `app/`, screens, server code, platform-specific files. |
| [expo-router](references/expo-router.md) | Expo Router navigation: file-based routes, links, native stacks, modals, sheets, native tabs, and headers. |
| [expo-animation](references/expo-animation.md) | Polished React Native animations and gestures with Reanimated, Gesture Handler, Expo Router, and expo-haptics. |
| [expo-native-ui](references/expo-native-ui.md) | Native-feeling screen styling, semantic colors, controls, icons, media, and visual effects. |
| [expo-design-system](references/expo-design-system.md) | In-app design systems: a token theme (color, spacing, typography, radius, shadow, motion), reusable component conventions, and design-system drift audits. |
| [expo-ui](references/expo-ui.md) | `@expo/ui` native components: universal cross-platform first, plus SwiftUI and Jetpack Compose. |
| [expo-data-fetching](references/expo-data-fetching.md) | API calls, React Query, SWR, caching, offline support, and Expo Router data loaders. |
| [expo-dom](references/expo-dom.md) | Expo DOM components for gradually using web code in native apps. |
| [expo-web-to-native](references/expo-web-to-native.md) | Migrating an existing web/React app (Next.js, Vite, CRA) to a native iOS/Android app with Expo. |
| [expo-module](references/expo-module.md) | Expo native modules and views with Swift, Kotlin, TypeScript, config plugins, and autolinking. |
| [expo-brownfield](references/expo-brownfield.md) | Adding Expo or React Native to an existing iOS or Android app. |
| [expo-dev-client](references/expo-dev-client.md) | Development clients (local builds are free; EAS Build/TestFlight is a paid step). |
| [expo-examples](references/expo-examples.md) | The `expo/examples` repo of `with-*` integrations to adapt or scaffold from. |
| [expo-app-clip](references/expo-app-clip.md) | iOS App Clip targets, AASA files, associated domains, and Smart App Banners. |
| [expo-upgrade](references/expo-upgrade.md) | Expo SDK upgrades, dependency conflicts, deprecated packages, and cache cleanup. |

## Services & paid distribution

Skills whose core purpose uses paid Expo Application Services (EAS). Each `SKILL.md` opens with a costs/plan-limits callout.

| Skill | Use it for | Paid dependency |
| --- | --- | --- |
| [eas-app-stores](references/eas-app-stores.md) | Build and submit iOS/Android apps: Expo and other React Native projects, plus existing native apps; TestFlight, profiles, versioning, and metadata. | EAS + Apple/Google accounts |
| [eas-hosting](references/eas-hosting.md) | Deploying Expo websites and Expo Router API routes to EAS Hosting: secrets, custom domains, Cloudflare Workers. | EAS Hosting usage |
| [eas-workflows](references/eas-workflows.md) | EAS Workflow YAML files and CI/CD automation. | EAS build/compute minutes |
| [eas-observe](references/eas-observe.md) | EAS Observe setup and launch, route, event, and version metrics. | EAS Observe usage |
| [eas-update](references/eas-update.md) | EAS Update setup, OTA publishing, runtime compatibility, testing, and debugging. | EAS Update usage |
| [eas-update-insights](references/eas-update-insights.md) | EAS Update health, crash rates, launch counts, payload size, and rollout gates. | EAS Update usage |
| [eas-simulator](references/eas-simulator.md) | Remote iOS/Android simulators on EAS cloud, driven from the CLI or an agent, with browser preview. | EAS Simulator usage |
