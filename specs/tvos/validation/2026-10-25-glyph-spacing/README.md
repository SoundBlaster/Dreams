# Restored TV glyph row spacing — 2026-10-25

Runtime/test source `b34f92a831851701b3f64d7f630c6581901a418d`, based on the
App Store target branch. The owner supplied a film frame and reported excessive
space between restored glyph rows. Pending clarification, this implementation
assumes vertical gaps on Apple TV; the macOS rain geometry remains unchanged.
The supplied frame is a qualitative reference, not a pixel-calibrated target or
proof of film fidelity. No new source font/contour is generated or installed.

## Geometry and boundaries

The previous TV renderer applied a fixed1.32-row quad to a28-pixel atlas crop,
independent of the font's body metrics. DreamsMatrix's font point size26 and
cap-height780/1024 yield a common body of about19.805 pixels. The common body
therefore occupied about93.4% of a row, while the median PUA vector height was
about88.3%. Actual raster coverage differs due to hinting/antialiasing.

FilmAtlas now derives one uniform XY factor (about1.0710657) from that common
cap height at atlas construction. The unchanged cropped core and padded halo
UVs share this factor around fixed grid centers. Short punctuation is not fitted
per glyph; outline proportions and individual overshoots remain natural. Classic
mode keeps scale1. Row/column counts, simulation clocks, preferences, repertoire,
font files and source artwork are unchanged. No per-frame font measurement or
extra geometry instances are added. Larger quads cover about14.7% more area;
no GPU/frame-rate performance result is inferred from the tests.

Affected TV claims: `dreams.tv.rain/resources`, parent `fps` and existing
appearance/platform-boundary obligations. `TelevisionApplication.GlyphResources`
owns common-body sizing; FPSReadout inherits it. `dreams.rain.fps/appearance`
retains identical active-rain quad sizing via an optional FPSGrid scale, default1
for existing macOS/classic consumers. Cadence, lifetime and opt-in semantics stay
unchanged. Current bindings/maps/source identities are refreshed; old snapshots
and observations remain historical. Both packages remain descriptive drafts.

## Verification

`GlyphSpacingTests` samples the actual restored Metal atlas (alpha threshold32)
and quads produced by MatrixRenderer.makeCells, rather than only repeating a
scale formula. G21 spans20 raster pixels: its prior fixed-quad coverage computes
to0.942857 rows; the changed runtime quad yields1.009862. G25 remains4 raster
pixels and0.201972 rows. The test guards near-full body coverage, a short mark,
uniform XY aspect, FPS size alignment and unchanged classic scale. The before
number is calculated from the unchanged raster and pinned prior geometry, not
an old-app screenshot. Existing head/gap tests locate cells by grid center so
they continue to validate appearance independently of an old hardcoded size.

The complete TV unit/renderer-instance run passes21 tests on tvOS27.0's1080p
Apple TV4K simulator with Xcode27.1 (27A9275). It retains the known repeated-font
registration / duplicate-drawable-presentation test diagnostics. The focused
macOS PresentedFPSTests run reports five tests (four executed, one actual-Metal test skipped);
it covers the shared default/scaled grid, not a new macOS visual acceptance.
SwiftLint passes with its existing analyzer-rule configuration warning.

The actual [after frame](tv-rain-after.png) was captured from the launched app
with simctl and visually inspected. Full forms appear closely packed and short
marks remain short; it is not a matched before/after experiment. FPS was off in
this frame, so its alignment is covered by tests rather than a screenshot.
A bounded delegated check did not open a session; the root Xcode session attempt
requested project approval, and no hierarchy/session was available. The CLI
capture made no preference/menu edits. Capture/path failures were corrected by
relocating only this task's native PNG; source/user glyph work was preserved.
Neither geometry/source tests nor a simulator screenshot establish physical
Apple TV performance, font rights, film fidelity or owner acceptance. No physical
TV install, upload, review submission or new release is performed by this task.

[Source identity](../../evidence/2026-10-25-glyph-spacing/source-identity.json),
[checks](checks.json) and compressed logs retain source/tool/hash distinctions.
