# 100% native preview scale — 2026-10-15

Runtime `4973f2576232fab2c33398e6c49ce461cd5ad95d`; [current source/map identities](../../evidence/2026-10-15-scale/source-identity.json).
Earlier preview baselines remain historical. Source bytes tested before the commit match the pinned snapshots.

User requirement: show rain at 100% size inside the panel, not a reduced full-screen scene. The user explicitly
deferred the toolbar blur overlap; no layout/material/scroll-edge change is included. The added preview_scale
constraint is folded into the existing LivePreview host draft; stable role/other claim IDs remain unchanged.

RainPreviewSession takes the hosting NSScreen frame and converts it through the MTKView backing coordinates.
RainRenderer uses that screen-sized Metal viewport and resolution; the smaller drawable clips its top-left
portion. Glyph size, spacing, auto/manual grid and visual velocity match that display's fullscreen scene.
Panel resize changes the crop. Screen/backing notifications redraw a paused preview with the new reference.
Fullscreen and ordinary offscreen calls keep their actual drawable/output size as their default viewport.

[56 unit/Metal tests](unit-metal.log) pass. The [focused GPU crop test](crop-gpu.log) covers auto/manual 80 columns
and 1x/2x backing sizes (four cases): every crop row equals the corresponding full-screen row byte-for-byte,
and nonblack glyph content is required. This verifies cropping without shrinking rather than only checking
configuration fields. Existing head/pulse/transparent-fade regressions also pass. [Lint](lint.log) and
[HC/SpecPM structure](structure.log) are separate evidence; [commands/tools](runs.json) record their identity.

Delegated device-interaction CUA verification on the isolated rebuilt local preview app observed visibly
larger glyphs and about 21 columns in a roughly 576-backing-pixel panel, rather than the full screen's 110.
Streams clip at panel edges. No original rain/preferences were changed. Blur was deliberately not examined.
This is local macOS 27 / Swift 6.4 observation; physical multi-display movement, macOS15 and TV remain unobserved.
Earlier SCK fixture artifacts remain documented in the historical preview baseline; no new SCK trace is claimed.
