# Native embedded rain preview — 2026-10-15

Runtime `1c8ba19844fffad464ac7dd7dfce8aba7dac0bb7`; [current source/map identities](../../evidence/2026-10-15-preview/source-identity.json).
Changed source is snapshotted; unchanged pinned snapshots retain identical hashes. Changed HC maps
are separately identified. Earlier baselines remain historical and drafts remain unaccepted.

## Implementation and impact

`NativeSettingsModel` retains one window-local preview session. `RainPreviewSurface` binds an MTKView
with identity guards for replacement, visibility and delegate callbacks. It releases its renderer on
hide, full occlusion, minimize and close. Local Pause freezes the posed clock; a later static repaint
may redraw that same time. Reduce Motion initially pauses and enabling it pauses; explicit Play works.
A six-second starting time populates a still without advancing the fullscreen renderer or launching rain.
The shared controller applies existing tuning; background/glyph changes rebuild only the preview renderer.
The default fullscreen draw path still passes nil posed time. The shader, motion/search/head/pulse
algorithms, hooks, glyph/font/checkpoints, display/input ownership and tvOS source are unchanged.

Stable `dreams.settings.host` default_off/native_controls/one_settings_owner/lifetime/overlay_exit IDs
retain their requirements. preview_limit now covers the authorized embedded-preview stage, with glass
still excluded. independent_preview/preview_lifetime/preview_playback recover the additional boundary
inside this host draft. Border hashes now include the consumed SettingsPreviewRegion and renderer.
`dreams.overlay.*`, `dreams.rain.drop_motion`, search_occupancy, head_visibility and glyph_pulse preserve
stable identities/requirements; changed integration source is repinned in their packages.

## Executed checks

- [Unit/Metal log](unit-metal.log): 55 tests in 18 suites pass on macOS 27.0/arm64, Swift 6.4.
  New checks cover lazy allocation/no-overlay, shared tuning, paused clock, background/glyph rebuilds,
  resource release, replacement identity and Reduce Motion. Existing offscreen head/pulse/alpha checks pass.
- [Screener SDK log](trace.log), [timeline](timeline.jsonl), [frame hashes](frames.json): 11 compositor
  keyframes, all with positive preview frame counts, at widths 1000/560, light/dark and both backgrounds.
  Capture is of the exact test window via existing Screen Recording access, with no desktop fallback.
  [Run receipts](runs.json) distinguish commands/environment/exit codes; [tools](tools.json) pin tooling.
- [Lint](lint.log) and [structure](structure.log) are fresh structural/source checks, separate from pixels.
  SwiftLint retains its pre-existing unused_import analyzer-configuration warning. SpecPM unresolved
  external capabilities remain warnings; validation does not establish runtime conformance.

## Actual application observation and remaining limits

A delegated device-interaction verification used CUA on an isolated `Dreams Preview.app`, bundle ID
`ru.egormerkushev.dreams.preview-verification`, --native-settings and an empty isolated feed. Visible
Metal glyphs/pale heads animate; Pause holds a still, Play resumes, manual Columns changes the preview,
and minimize/AX Raise restores it. Actual wide General/Rain layouts have no clipped headings. Light
Aqua was additionally forced only in the disposable bundle Info.plist with NSRequiresAquaSystemAppearance;
both light and dark actual-window screenshots show complete Live Preview/Grid headers and clean sliders.
This Info.plist override is not production source or a new user preference.

Screener MCP sessions/timeline/frame inspection found a toolbar-overlap band and slider artifacts in
SwiftPM/SCK fixture images (also reproduced after host/appearance reconciliation). These images prove
Metal content and fixture states, **not a clean visual acceptance baseline**. That artifact did not
reproduce in the actual app in either appearance. A SwiftPM window-lifecycle experiment without a normal
NSApplication event loop was discarded as unreliable; automated tests cover the session transitions,
while actual minimize/playback observations are recorded separately. No physical TV, macOS 15 runtime,
VoiceOver/full keyboard traversal, error injection or fullscreen display-topology acceptance is claimed.

Ordinary launch still uses legacy settings; --native-settings remains an explicit default-off route.
Whole-window glass/open shapes and shortcut-recording migration remain separate work. User rain was
only stopped for bounded GUI observation and restored afterwards; its preferences were not edited.
