# Native settings baseline — 2026-10-14

Source and resolved Screener identities are pinned in the sibling evidence record.
The catalog and native host are distinct apps/entrypoints. This is a descriptive
draft; local tests do not establish acceptance of the future visual design.

Local evidence: release build with warnings as errors; all 38 Swift tests; new
bindings/window synchronization, default-off routing, input ranges and shared
activity timer; Screener 0.2.0 hierarchy trace with 11 explicit form states;
read-only local stdio MCP session/timeline/frame retrieval; package/resources;
FSD, SwiftLint, Ruff, shell, localization and HC/SpecPM structure.

AppKit hierarchy frames are not compositor screenshots. Recorded hierarchy frames show missing selected-sidebar text
and incomplete material/slider pixels. Corresponding on-screen behavior remains
unverified; this may be a capture limitation and is not declared a passing visual check. Keyboard,
VoiceOver, precise system appearance and live compositor capture remain
unobserved while the Mac is locked. The optional ScreenCaptureKit test backend
requires an unlocked GUI and previously granted Screen Recording permission;
no new permission was requested and no desktop capture fallback was added.

The original checkout's glyph edits/checkpoints and font data remain untouched.
Tests run under their own process identity and restore touched preference keys.
CI was not monitored, per user request. No merge, install or release occurred.

Tool identities are recorded in tools.json. Hypercode does not support the queried
`--version` spelling; its binary hash is recorded instead. Structural commands
completed with exit 0. External platform/controller requirements remain warnings
(1 host, 1 catalog, 11 overlay, 4 rain, 8 glyph); no dependency was deleted to
remove a warning. No CI query or watcher was used during this continuation.
