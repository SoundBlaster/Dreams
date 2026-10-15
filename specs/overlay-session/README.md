# Overlay lifecycle and exit

This package contains four **descriptive draft** contracts initially recovered
from merged main `1ce194748720e40e1eb9737e63bb37797c5840b1`. The session/status
contract has a later capture-visibility correction; unchanged contracts retain
their initial bindings. Current source identities and validation are linked below:

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

Exit-button auto-hide uses a tracked hover flag updated by mouse movement.
It is not initialized from the cursor on presentation, so a stationary cursor
already over Exit does not prevent hiding after four seconds (matrix O7).

## State and observation

| State | Meaning |
| --- | --- |
| Stopped | No requested session/owned overlays; stop clears timers and releases any active sleep assertion |
| Requested, no windows | No eligible target remains after topology change; saved display choices and requested session can remain |
| Owned windows | Requested and nonempty manager ownership; `rain_visible` is true only when capture suspension is also false |
| Capture-suspended | `rain_suspended_for_capture` is true and `rain_visible` is false; windows are ordered out, while request, expiry, sleep assertion and renderer ownership remain |

The capture suspension flag stays true through the greater-than-0.5-second clear
grace period and resets on restoration or stop. These observations do not
establish pixel visibility. Screenshot exclusion is
best-effort window policy; capture tools may differ. `dreams_prepare_ui` calls
session stop so opaque windows also release input ownership. A virtual agent
workspace is excluded from rain targets and survives ordinary stop; workspace
creation/destruction itself remains outside this package.

[Claim/scenario matrix](matrix.md) records source evidence, parent obligations
and review decisions. [Source identities](evidence/2026-10-13/source-identity.json)
pin full files or exact excerpts with full-source hashes. [HC map](../hypercode/overlay-session.hc)
and [profiles](../hypercode/overlay-session.hcs) describe composition, not runtime
configuration. [Initial validation](validation/2026-10-13/README.md) and the
[P2 review correction](validation/2026-10-13-review-p2/README.md) check structure only.
The [historical capture source identities](evidence/2026-10-13-capture-status/source-identity.json)
pin the session correction at `bd5d783`.
The [capture-status correction](validation/2026-10-13-capture-status/README.md)
records fresh deterministic native-overlay tests and the current source baseline.
The initial documentation pass did not run live tests. Physical screenshot-picker
recognition, keyboard and display-topology behavior remain separately unverified.

## FSD integration refresh — 2026-10-13

Current implementation: `691d94b65eb8fd1687b09cef7ff4f6f5c2776c83`. [Identities](evidence/2026-10-13-fsd/source-identity.json)
map old paths to FSD paths and pin the extracted settings/app composition.
[Fresh validation](validation/2026-10-13-fsd/README.md) is separate from the historical
source-reading pass above. Existing display/session/input claims and IDs still apply.
SettingsPageController now owns recording and cleanup; DreamsDelegate retains it
and forwards termination. SettingsWindow wires Esc to the same rain controller.
RainScreenManager, overlay panels, Carbon registration, display policy and renderer
algorithms are byte-identical to main apart from paths; controller body is unchanged
after moving DreamsPreset and DreamsError to their own files.
The tvOS foreground app is represented only in coarse orientation and remains
outside these macOS contracts. No physical-keyboard/Apple-TV claim follows from
GUI or simulator passes. PRs #18–20 are independent and remain outside this merge.

Current capture-status FSD refresh: [2026-10-14 validation](validation/2026-10-14-capture-fsd/README.md). Suspended status is false without owned overlays.

Current integrated baseline: [2026-10-14 motion-stack](validation/2026-10-14-motion-stack/README.md). Prior source/test records remain historical.

Current integrated baseline: [2026-10-14 search-stack](validation/2026-10-14-search-stack/README.md). Prior source/test records remain historical.

Current glyph-pulse integration and separate execution/structural evidence: [2026-10-14 pulse](validation/2026-10-14-pulse/README.md). Earlier baselines remain historical.

Current native shortcut integration: [2026-10-15 shortcut](validation/2026-10-15-shortcut/README.md). Earlier evidence remains historical.

Current startup-conflict retry fix: [2026-10-15-shortcut-retry](validation/2026-10-15-shortcut-retry/README.md). Historical evidence remains on its original baseline.
