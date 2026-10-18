# Native settings host (descriptive draft)

The production app now has two settings presentations backed by the same
`DreamsController`. The launch flag `--native-settings` opts into SwiftUI;
absence preserves the existing AppKit window, and `--legacy-settings` wins
if both flags appear. Nothing enables this feature through saved preferences.

```sh
make app
open -n dist/Dreams.app --args --native-settings
make test-native-settings-trace
# Optional compositor stills: unlocked GUI and previously granted Screen Recording access.
DREAMS_NATIVE_CAPTURE_BACKEND=screen-capture-kit make test-native-settings-trace
```

The native window uses NavigationSplitView, a selection List, grouped Form,
Section, Slider, Toggle, Picker, ColorPicker, native buttons, error alerts
and a reset confirmation. Seven sections cover general/run time, appearance,
rain, background, agent words/hooks, displays and advanced actions. The host
links only the `DreamsSettingsUI` library; the standalone catalog stays separate.

Both windows use the existing persisted keys, controller operations, renderer
propagation and activity timer. No settings snapshot is independently saved.
Controller change notifications invalidate the native observation adapter and
refresh legacy controls. Opening either window retains the existing
`stopForReopen` behavior. Closing/reopening retains the native window's section
selection; terminal cleanup removes observers and stops the timer.

Manual columns are 24–240 (zero means automatic), density/search/spread/idle
0–100%, speed 0.25–3×, sequential fade 1–16 rows, acceleration −120–0 rows/s²,
glow 0–300%, and word brightness 0–200%. These are current production ranges,
not new product limits. Native bindings reject nonfinite values and constrain
scalar input to those ranges. Runtime presets and separate transparent/opaque
color/glow profiles retain controller semantics. Failures expose the controller's
actual state and an alert; the controller operations are not promised atomic.

## Assembly and limits

- The app retains SettingsPageController; it retains either/both windows and the
  native model. The adapter references the same controller and weakly references
  its settings owner. This UI package owns no renderer or saved state.
- Display mode and selection go through existing display reconciliation; hook
  buttons go through the existing installer and plugin-managed hooks stay disabled.
- General records the stop shortcut directly, with Cancel/Esc and Reset. Advanced
  retains explicit legacy access. Both windows share a temporary window-scoped
  recorder; changing section, closing/defocusing its window or deactivating/hiding
  the app cancels capture. Conflicts retain the saved setting and show an error;
  Carbon registration/rollback remains fallible. No new saved key or permission is added.
- Live Metal rain uses a separate window-local renderer and clock with the shared
  controller tuning. One Metal surface sits behind forms and an open region beside them in wide layouts
  or above them in narrow layouts. The backdrop shows a 100% crop of the hosting display-sized scene, using
  backing pixels for Retina: glyphs/grid spacing match fullscreen and resizing
  reveals a different area without shrinking all columns. System materials cover the forms; macOS 26 extends the backdrop under native navigation.
  Rain pilots a scrollable title/description and three native grouped sections,
  plus an outlined open preview region. All sections use the shared panel with 16-point rounded corners.
  Both forms and preview surfaces follow system appearance and become opaque with Reduce Transparency or increased contrast.
  The window does not expose the desktop through its background.
- Preview pauses/releases GPU ownership when hidden, minimized, closed or fully
  occluded. Local Pause/Play never starts the fullscreen overlay. Reduce Motion
  initially pauses; explicit Play is allowed. The posed clock starts at six seconds
  for a populated still and freezes while paused. Failure shows a native Retry action.
- Screener records explicit model/form states through its 0.2.0 test SDK.
  The optional test-only ScreenCaptureKit product captures the exact test window
  and owner with existing authorization; failure never substitutes desktop or
  hierarchy pixels for a requested compositor frame.
  Hierarchy capture can omit/alter compositor materials and selection pixels.
  Native keyboard, VoiceOver, screen pixels and macOS 15 runtime remain separate
  acceptance work; the development Mac was locked during this pass.
- tvOS, overlay input/display algorithms, glyph files and checkpoint data are not
  changed. Existing overlay/rain contracts keep stable IDs with a new source baseline.

[Contract](specs/host.spec.yaml), [map](../hypercode/settings-host.hc),
[source and validation baseline](validation/2026-10-14/README.md).

## Local UI dependency baseline

The host requires `dreams.settings.ui`, provided by the
[catalog/UI package contract](../settings-catalog/specs/catalog.spec.yaml).
This means the library compositions, not the catalog executable. The binding
border and [current source identity](evidence/2026-10-14-ui-border/source-identity.json)
include the local SwiftPM manifest and consumed compositions. The current material stage
adds SettingsMaterialPanel to the border; SettingsPreviewRegion remains a catalog primitive.
`Package.resolved` does not pin a local package. Changing either input invalidates
the host's native-control baseline and requires renewed verification.
The original source/validation records remain historical.
[Review correction checks](validation/2026-10-14-ui-border/README.md).

Current glyph-pulse integration and separate execution/structural evidence: [2026-10-14 pulse](validation/2026-10-14-pulse/README.md). Earlier baselines remain historical.

Current embedded preview implementation and validation: [2026-10-15 preview](validation/2026-10-15-preview/README.md). Earlier records remain historical.

Current 100% display-scale correction: [2026-10-15 scale](validation/2026-10-15-scale/README.md).

Current rain/material composition: [2026-10-15 materials](validation/2026-10-15-materials/README.md).

Current native shortcut integration: [2026-10-15 shortcut](validation/2026-10-15-shortcut/README.md). Earlier evidence remains historical.

Current compact shortcut layout: [2026-10-15-shortcut-compact](validation/2026-10-15-shortcut-compact/README.md). Behavior and stable claim IDs remain unchanged.

Current startup-conflict retry fix: [2026-10-15-shortcut-retry](validation/2026-10-15-shortcut-retry/README.md). Historical evidence remains on its original baseline.

Current native parity pass: [2026-10-16](validation/2026-10-16-parity/README.md), including hook accessibility and narrow status fixes.

Shared slider column layout: [2026-10-18](validation/2026-10-18-alignment/README.md).

Adaptive slider P2 correction: [2026-10-18 review](validation/2026-10-18-alignment-review/README.md).

Rain composition pilot: [2026-10-18 composition](validation/2026-10-18-rain-composition/README.md).

Additional width grows the preview, not forms: [2026-10-18 allocation](validation/2026-10-18-preview-growth/README.md).

Shared rounded panel correction: [2026-10-18 corners](validation/2026-10-18-panel-corners/README.md).

Dense tick cleanup and native SDK appearance: [2026-10-18 SDK/sliders](validation/2026-10-18-native-sliders/README.md).

Active rain-color tint: [2026-10-18-rain-tint](validation/2026-10-18-rain-tint/README.md).

Native Liquid Glass panels: [2026-10-19-liquid-glass](validation/2026-10-19-liquid-glass/README.md).
