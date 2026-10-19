# Permanently visible native sidebar — 2026-10-19

Runtime `2691c3aca14488ff6fcedf78676dd11a3af01641`. [Source/map baseline](../../evidence/2026-10-19-fixed-sidebar/source-identity.json).

The owner explicitly replaced the earlier hide/show product requirement: the
sidebar must stay visible. Host native_controls draft.14 now describes a balanced
NavigationSplitView with constant all-column visibility. App visibility state,
buttons, Control-Command-S registration, hidden-detail recovery layout and obsolete
localized toggle text are removed. The native auto sidebar toolbar item remains
removed at its owner. The brand header remains, with44pt top inset instead of the
former button row. Selection, renderer, preferences and shared UI provider do not
change. Stable Navigation/Forms roles and claim IDs remain.

Old hide/show QA is historical for the old requirement; it is not current fixed
sidebar evidence. No new static-view unit tests or repeated renderer tests were
added. Actual UI checks, source review and structural validity are separate.
Narrow resizing, macOS15 physical, window dragging and full VoiceOver remain
unverified acceptance items. No release/default-on rollout or CI waiting.

## Local checks

[Release build](app-build.log), [lint](lint.log), [156 matching bilingual keys](localization.log)
and [HC/SpecPM](structure.log) passed. All57 current/snapshot hashes verified.
Known SwiftLint unused_import and draft external-capability warnings remain.
Swift6.4; SpecPM0.2.0; Hypercode binary SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Verified TB5 scratch, active SDK27/minos15 metadata guard. No new unit-suite pass
is claimed for this static presentation simplification.

## Actual SDK27 observation

[Wide screenshot](wide.png), [report](ui-report.md): real app icon, Dreams title,
complete subtitle and all seven native rows are visible. No toggle/hide buttons
or toolbar appear in pixels or AX. A Control-Command-S press leaves the sidebar
and selected Rain section unchanged. Production preferences/system settings were
not changed. Narrow resizing and drag behavior remain unverified.
