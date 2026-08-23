---
name: flutter-ui-automation
description: "Initialize deterministic Flutter UI automation rules based on integration_test, stable semantics, AI-assisted exploration, and assertion-driven regression."
---

# Flutter UI Automation Initialization Capability

Activate only for a runnable Flutter application package evidenced by `pubspec.yaml`, `lib/main.dart`, and at least one platform directory. Detect each package independently in a monorepo.

## Outputs

Create or incrementally upgrade one focused rule in the project's existing AI rules directory, otherwise `docs/references/ai-rules/02-Flutter自动化测试.md`. Add only a short trigger and path index to project-level AI instruction files.

Initialization establishes the protocol; it must not add app dependencies, create a generic driver in production code, or claim unsupported platforms. Record existing `integration_test`, driver, test-entry, Key/Semantics, and platform evidence. Mark missing runtime pieces as not implemented.

## Required Protocol

- Flutter-rendered UI interaction uses official `integration_test` plus a project `AITestDriver` wrapper. Do not drive Flutter UI with screenshots, visual coordinate guessing, system mouse control, ADB input, WinAppDriver, or direct coordinate clicks.
- Locate actions through stable `ValueKey<String>` and Semantics. New interactive controls require stable identifiers; tests must fail structurally on zero or multiple matches.
- Use bounded condition waits such as `pumpUntil(predicate, timeout, interval)`. Do not depend on unbounded `pumpAndSettle()` or fixed sleeps for asynchronous correctness.
- AI may inspect a redacted semantic snapshot and propose allow-listed actions. Validate its JSON, key uniqueness, action type, and argument limits. Never send passwords, tokens, phone numbers, or user content to an LLM.
- AI exploration records a replayable Key-based trace. CI and final PASS/FAIL replay deterministic actions and use explicit Dart `expect` assertions; an LLM is never the sole test oracle.
- For multiple Flutter packages, share the action protocol/driver core where existing package boundaries permit, but keep a thin launch adapter per package. Do not force different app entrypoints into one test file.
- System permission dialogs, native WebViews/platform views, file pickers, share sheets, Bluetooth pairing UI, and real IME behavior are outside Flutter semantics coverage. Report the boundary and use a separately authorized platform strategy when required; never silently mark them covered.
- Run commands from each package root and switch only to platforms that actually exist in that package.

## Verification

- Capability is absent from non-Flutter projects and pure Dart packages.
- Generated rules list detected package roots and supported platform evidence.
- Any existing desktop/mobile integration test uses deterministic Dart assertions for PASS/FAIL.
- If `AITestDriver` is absent, initialization says `not implemented` and leaves implementation for a planned testing task.
