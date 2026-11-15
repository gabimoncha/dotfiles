---
name: design-engineering
description: Load this skill before you build, change, or review UI components in a web or React Native app. Covers forms and accessibility, toasts and notifications, animation and motion, typography, color, layout, and product copy.
license: MIT
metadata:
  author: flowcopilot
  upstream: emilkowalski/skills@2d228630ba1446365f614a108cb8252f1feda202
  upstream_jakub_krehel: "jakubkrehel/skills@592aedc44d7d5b3e29740984252902f3e5402a1c"
---

<!-- Modified by Flow Copilot from emilkowalski/skills. -->

# Design Engineering

Use the target project's stack, design tokens, and installed libraries to select references. Read only the relevant workflow and its supporting files.

## Choose a source

- For motion — building, reviewing, auditing, or naming animations, gestures, and transitions on the web or in Expo — start with Emil Kowalski's workflows. [emil-design-eng](references/emil-kowalski/emil-design-eng/index.md) holds the shared philosophy.
- For static interface quality — UI polish, typography, color, layout, accessibility, and product copy — use the matching Jakub Krehel `better-*` workflow. [better-interface](references/jakub-krehel/better-interface/index.md) combines them into one review.
- When both sources cover a topic, such as animation in `better-ui` or typography in `apple-design`, prefer the source whose focus matches the task and keep the project's existing tokens.

A former upstream skill name, such as `review-animations` or `better-colors`, now refers to its index.md reference in the same source directory. Those workflows are available whenever this skill is installed; load them when an imported instruction asks for another skill. Relative paths remain relative to the imported file.

Upstream instructions that describe a first response for an invocation without a question apply when the user selected that workflow explicitly. Workflows listed as explicit-only were user-invoked upstream; do not start them unprompted.

This bundle imports the skills directories of both repositories. Plugin metadata, agent UI metadata, and root-level files are not included.

## Emil Kowalski

- [animate-expo](references/emil-kowalski/animate-expo/index.md): Build animations in React Native and Expo, making the decisions in the order that determines whether they feel right — should it animate, which thread it runs on, which properties, spring or timing, how the gesture hands off, how it degrades.
- [animate](references/emil-kowalski/animate/index.md): Build an animation from scratch, making the decisions in the order that determines whether it feels right — should it animate at all, what purpose, which tool, which properties, which curve and duration, how it interrupts, how it exits.
- [animation-performance](references/emil-kowalski/animation-performance/index.md): Keep web animations inside the frame budget — animate composite-only properties, keep motion off the main thread when the page is busy, and find the cause when an animation drops frames.
- [animation-vocabulary](references/emil-kowalski/animation-vocabulary/index.md): Reverse-lookup glossary that turns a vague description of a web animation or motion effect into its exact term ("the bouncy thing when a popover opens" → Pop in; "the iOS rubber-band scroll" → Rubber-banding).
- [apple-design](references/emil-kowalski/apple-design/index.md): Apple's approach to interface design and fluid, physical motion, translated for the web.
- [ask-sonner](references/emil-kowalski/ask-sonner/index.md): Guide to Sonner, the React toast library — install and wire up the Toaster, pick the right toast() call, promise and loading toasts, updating, dismissing and persisting toasts, styling, theming and icons, positioning and multiple toasters.
- [break-ui](references/emil-kowalski/break-ui/index.md): Try to break a piece of UI by feeding it worst-case data — long names, unbreakable emails, one-letter names, missing fields, huge counts, zero items, long labels, non-Latin text, emoji, extreme numbers — then render it behind a "Demo data / Worst case" toggle and report everything that broke, with the fix for each.
- [emil-design-eng](references/emil-kowalski/emil-design-eng/index.md): This skill encodes Emil Kowalski's philosophy on UI polish, component design, animation decisions, and the invisible details that make software feel great.
- [find-animation-opportunities](references/emil-kowalski/find-animation-opportunities/index.md): Search a codebase or UI for places that don't animate but should, and reject everything that shouldn't.
- [improve-animations](references/emil-kowalski/improve-animations/index.md): Survey a codebase's animation and motion code as a senior motion advisor, then produce a prioritized audit and self-contained implementation plans for other agents (or cheaper models) to execute.
- [mobile-native](references/emil-kowalski/mobile-native/index.md): Make a web app feel native on a phone — the small CSS and meta-tag fixes that separate "a website in a browser" from something that feels installed.
- [write-swift](references/emil-kowalski/write-swift/index.md): How to write modern Swift well — modeling with value types, Swift 6 data-race safety and approachable concurrency (@concurrent, main-actor-by-default, actors, task groups), protocols and generics (some vs any), API design, performance and ARC, Swift Testing, macros, and the modern language features agents don't know about yet.

Only when the user explicitly asks for them by name or purpose:

- [pick-ui-library](references/emil-kowalski/pick-ui-library/index.md): Pick the right library for a given frontend task from a curated, opinionated list — numbers, OTP inputs, charts, command menus, virtualization, drag and drop, toasts, state, styling, and more.
- [prototype](references/emil-kowalski/prototype/index.md): Build multiple genuinely different versions of a UI piece you describe, rendered behind a visual picker so you can flip through them live and promote the one that feels right.
- [review-animations](references/emil-kowalski/review-animations/index.md): Reviews animation and motion code against a high craft bar derived from Emil Kowalski's design engineering philosophy.

## Jakub Krehel

- [better-accessibility](references/jakub-krehel/better-accessibility/index.md): Reviews and fixes keyboard and focus behavior, ARIA, accessible names, forms, screen-reader announcements, motion and zoom against WCAG 2.2.
- [better-colors](references/jakub-krehel/better-colors/index.md): Builds and checks color systems by generating palettes, naming semantic tokens, converting between formats and measuring contrast.
- [better-interface](references/jakub-krehel/better-interface/index.md): Reviews a screen, flow or whole interface across accessibility, layout, writing, typography, color and UI polish, and returns one ranked report.
- [better-layout](references/jakub-krehel/better-layout/index.md): Sets grouping, alignment, reading order, responsive structure and room for translated text, so a layout holds up when it is resized, translated or mirrored.
- [better-typography](references/jakub-krehel/better-typography/index.md): Sets and reviews how text renders, from the type scale and spacing to font features, wrapping, truncation and punctuation.
- [better-ui](references/jakub-krehel/better-ui/index.md): Polishes surfaces, icons and motion with exact values for border radius, optical alignment, shadows, icon states and animation.
- [better-writing](references/jakub-krehel/better-writing/index.md): Writes and reviews interface copy, from labels and errors to empty states and confirmations, so it matches the product's voice and tells people what to do next.
- [build-design](references/jakub-krehel/build-design/index.md): Builds UI from a Figma file or a design image so it matches the design, using the project's existing tokens and components.
- [teardown](references/jakub-krehel/teardown/index.md): Creates technical illustrations of physical objects and of how things work, such as display pixels or interface layers, with coherent views, fine linework and part fills.

Only when the user explicitly asks for them by name or purpose:

- [break](references/jakub-krehel/break/index.md): Renders a component you choose under every scenario that can reach it on a temporary page and stress tests it.
- [explain-interface](references/jakub-krehel/explain-interface/index.md): Explains how a website, a visual effect or an animation was built, from a live URL or a screenshot.
- [interface-review](references/jakub-krehel/interface-review/index.md): Reviews a branch, pull request or uncommitted change for the interface problems it introduced or regressed, across accessibility, layout, writing, typography, color and UI.
- [state-machine](references/jakub-krehel/state-machine/index.md): Renders every state of a component you choose on a throwaway page, with mock data and a switcher, so you can work on each state.
- [variant](references/jakub-krehel/variant/index.md): Builds multiple variants of a component you're working on and helps you iterate and pick one.
