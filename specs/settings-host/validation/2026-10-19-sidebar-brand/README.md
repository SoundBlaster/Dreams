# Sidebar identity header — 2026-10-19

Runtime `3ab3b050c76cb13b0a21fa62ee8f8715e63aedf2`. [Pinned source/map baseline](../../evidence/2026-10-19-sidebar-brand/source-identity.json).

Host native_controls (draft.13) and Navigation presentation extend the existing
sidebar with the current NSApplication icon, Dreams title and requested exact
Agentic Screensaver subtitle. Both language bundles carry that product phrase.
The64pt icon is decorative for accessibility; semantic title/subtitle combine as
one element. Native List selection, sidebar visibility/recovery and window buttons
remain unchanged. The clear header uses WindowDragGesture without a second click
action. No controls are restyled and no renderer, persistence or shared provider
changes. The header is a minor presentation detail in the existing host contract.

Source review establishes fallbacks and ownership; new actual screenshot results
are distinct evidence. Prior toolbar tests belong to their source baseline and
are not relabelled as new checks. No new unit tests for static branding were added.
No macOS15 physical, narrow resize, full VoiceOver or drag acceptance is claimed.

## Local checks

[Release build](app-build.log), [lint](lint.log), [157 bilingual keys](localization.log)
and [HC/SpecPM](structure.log) passed. Known SwiftLint unused_import configuration
and descriptive-draft external capability warnings remain. All57 current source/map
and snapshot hashes verified. Swift6.4; SpecPM0.2.0; Hypercode SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Build used verified TB5 checkout scratch with activeSDK27/minos15 metadata guard.
No release or CI waiting.

## Actual wide-window observation

[Actual SDK27 screenshot](wide.png) and [AX](wide-ax.txt) show the current Dreams
icon, Dreams title and complete one-line Agentic Screensaver subtitle. All seven
native section rows are visible in this window. AX combines the brand text as
Dreams, Agentic Screensaver. This is a visual/AX observation, not a full VoiceOver
interaction audit. The application bundle includes the real AppIcon.icns and fresh
localization resources; no production preferences or system appearance changed.

[Actual report](ui-report.md): hide removes the brand/list; Control-Command-S restores
the complete brand and seven rows with Rain selected. QA app left sidebar-visible.
