# Native rain/material composition — 2026-10-15

Runtime `3910ebf93779f8da807bf361f89873092db03b7d`. [Current source/map identities](../../evidence/2026-10-15-materials/source-identity.json).
Historical validation remains on its original baseline. Tested source bytes match the pinned runtime.

The owner chose rain behind system material surfaces. `material_composition` extends the
existing host draft and updates `preview_limit`/`independent_preview` for the authorized stage;
all stable IDs remain. One surface renders at 100% hosting-display scale beneath the forms
and an uncovered region. Native backgroundExtensionEffect on macOS 26 supplies the backdrop
under navigation. Its mirrored/blurred extension is a system visual treatment, not another
simulation or a claim of screen-coordinate continuity under the sidebar. Fullscreen settings,
algorithms, feature routing and shared ownership stay unchanged. This is not desktop transparency.

## Verification

- [57 local Swift/Metal tests](unit-metal.log) pass, including exact fullscreen crop comparisons
  for auto/manual columns at 1x/2x. A new regression mounts the actual SwiftUI hierarchy,
  repeatedly crosses the 700pt detail breakpoint and requires one identical Metal surface.
- [Catalog build](catalog-build.log) and [packaging checks](catalog-check.log) pass: static catalog,
  no production dependency, 84 matching EN/RU labels and separate signed application identity.
- [Screener SDK 0.2.0 recording](screener.log): 13 exact-window ScreenCaptureKit keyframes;
  [timeline](timeline.jsonl), [frame hashes](frames.json). Session
  `076096DD-AB87-411F-84E5-19458B774966` was inspected through Screener MCP sessions/timeline/frame.
  Dark/light and narrow captures show rain behind materials and an uncovered region; each marker
  has positive renderer frame count. Window high-contrast appearance was requested, but this
  alone does not prove propagation of the system accessibility environment or opaque fallback.
- Actual isolated app CUA/subagent checks: General/Rain readable, Pause freezes across captures,
  Play resumes. Narrow resize through CUA was not successful; narrow evidence is the SDK fixture.
- [Lint](lint.log), [HC/SpecPM structure](structure.log) and [commands/tools](runs.json) are separate.

The first layout-test trial used an AppKit event drain during concurrent tests and ended the
runner early; it was replaced by a cooperative yield and layout pass. The successful 57-test run
is the evidence. Test capture changes added two scenarios afterward; the full 13-frame scenario passed.

## Limits

Toolbar/scroll-edge blur still covers upper content in SCK fixture images; the user explicitly
deferred this issue. Slider ticks/underscores differ between captures and actual app states;
these images are evidence of composition, not final pixel acceptance. Reduce Transparency was
not changed globally and remains source-reviewed only. High-contrast appearance is not a verified
system-preference toggle. Native macOS 15, VoiceOver/full keyboard parity, physical multi-display
movement, TV and performance profiling remain unobserved. No original user rain or preferences
were modified. New settings stay explicitly opt-in; no merge or release is claimed.

Apple API basis: [Material](https://developer.apple.com/documentation/SwiftUI/Material),
[backgroundExtensionEffect](https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect()),
[Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass).
