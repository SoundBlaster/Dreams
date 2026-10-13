# Overlay lifecycle and exit

This package recovers four **descriptive draft** contracts from merged main
`1ce194748720e40e1eb9737e63bb37797c5840b1`:

- [Display targets](specs/displays.spec.yaml): automatic/all/selected policy,
  saved IDs and excluded agent workspace.
- [Presentation](specs/presentation.spec.yaml): window reconciliation, input
  configuration and conditional focus return.
- [Exit input](specs/exit.spec.yaml): local Esc, per-screen exit button and
  fallible global Carbon shortcut.
- [Session](specs/session.spec.yaml): parent assembly, start/stop/resume,
  timers, sleep assertion and screenshot-tool suspension.

The parent contract connects individually correct children: OS input must reach
an appropriate window, a child callback must invoke the same controller stop,
and stop must release every owned overlay and session resource. A display
selection test or one closed panel cannot prove that entire path.

## Profiles

| Profile | Duration | Input and exit |
| --- | --- | --- |
| Interactive opaque | Saved run time; default 1 hour, or until stopped | Key-capable rain; local Esc / per-screen Exit button / registered hotkey / Stop |
| Interactive transparent | Until stopped | Mouse pass-through, no key focus or Exit button; hotkey or explicit Stop |
| Agent opaque | 1–3600 seconds, default 300 | Same opaque routing; timer and agent stop also apply |
| Agent transparent | Same finite agent duration | Same transparent routing; timer and agent stop also apply |

Esc is **local**, not a global interception. An uncovered application's Esc
stays with that application. Settings-window shortcut recording has its own
Esc-cancels-recording behavior. `resume` starts a new interval using the last
full duration; it does not continue the former remaining deadline.

## State and observation

| State | Meaning |
| --- | --- |
| Stopped | No requested session/owned overlays; stop clears timers and releases any active sleep assertion |
| Requested, no windows | No eligible target remains after topology change; saved display choices and requested session can remain |
| Owned windows | Requested and nonempty manager ownership; this is the current meaning of status `rain_visible` |
| Capture-suspended | Owned windows are temporarily ordered out; request, expiry and renderer ownership remain |

These observations do not establish pixel visibility. Screenshot exclusion is
best-effort window policy; capture tools may differ. `dreams_prepare_ui` calls
session stop so opaque windows also release input ownership. A virtual agent
workspace is excluded from rain targets and survives ordinary stop; workspace
creation/destruction itself remains outside this package.

[Claim/scenario matrix](matrix.md) records source evidence, parent obligations
and review decisions. [Source identities](evidence/2026-10-13/source-identity.json)
pin full files or exact excerpts with full-source hashes. [HC map](../hypercode/overlay-session.hc)
and [profiles](../hypercode/overlay-session.hcs) describe composition, not runtime
configuration. [Validation](validation/2026-10-13/README.md) checks structure only.
No live overlay, physical keyboard, capture or display-topology test was run
in this documentation pass; existing test code is an expectation, not a new pass.
