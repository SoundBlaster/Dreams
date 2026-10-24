# Desktop ownership / reopening — 2026-10-24

Runtime/test source: `a0cd20994743c20f941414be99b407d9b00cd11c`.
[Current changed-source identities](../../evidence/2026-10-24-single-instance/source-identity.json).

The owner requested one desktop instance to prevent competing rains.
`dreams.desktop.single_instance` covers startup admission, atomic user-local
lease lifetime, interactive handoff, exclusive full-control MCP/lab ownership,
and independent publishers/offline tools. `dreams.desktop.main_menu` retains
native commands; an exclusive accessory owner can promote on explicit GUI reopen.
Independent publishers cannot promote themselves into another GUI.

`DesktopInstanceTests` covers argument precedence, nonblocking contention,
persistent inode reuse, process-exit recovery, fail-closed I/O and publisher
reopen refusal. The actual packaged-app process and native UI probes are recorded
separately in results.json and process-results.json after execution.

A close/reopen UI check reproduced a frozen preview with Pause displayed.
Debugger inspection confirmed a visible, unpaused MTKView whose session clock
and renderer frame count stopped advancing. Resetting the close latch and
selecting native continuous drawing alone did not cure the retained-view issue.
After an observed window close, reopening now replaces only the Metal canvas,
retaining the window, navigation and Play/Pause choice. Ordinary repeated
presentation and adaptive layout retain the surface. The session explicitly uses
continuous MetalKit drawing during playback and event-driven drawing when paused.
`dreams.settings.host/preview_reopen` owns that contribution.

Final native checks on source `a0cd20994743c20f941414be99b407d9b00cd11c` observed changing glyphs before
and after one close/reopen, with the General section and Pause choice preserved.
CUA observations immediately reopened the window, so a stable closed state was
not established; the close action and subsequent rendered motion were observed.
Unit structure alone does not establish rendered motion.

The exploratory hosted preview test could not establish initial native-window
visibility in the SwiftPM host; it is not claimed as a passing test and was not
kept as a known-failing test. Product-window observations are separate.

[NSWorkspace native reopening](https://developer.apple.com/documentation/appkit/nsworkspace/openapplication(at:configuration:completionhandler:))
uses createsNewApplicationInstance false. Distributed notifications are
user-session requests to the sole lease owner, not full-control RPC forwarding.
Historical binaries do not gain the lease retroactively; compatible older regular
GUI instances are reused at new startup. This task does not replace /Applications,
merge PRs, release builds, or validate tvOS behavior/performance.
