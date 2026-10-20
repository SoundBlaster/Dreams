# Television rain and clock — descriptive draft

The [draft boundary](specs/television.spec.yaml) covers `dreams.tv.rain` and the
[television map](../hypercode/television.hc) / [properties](../hypercode/television.hcs).
It recovers the TV host separately from existing macOS-only renderer contracts.

| Role | Consumer question / claim | Assembly obligation |
|---|---|---|
| Tuning | Will saved TV values survive? / persistent_tuning | Preserve keys, normalize edits and apply defaults only for missing/new values |
| Simulation | Do motion/search match desktop? / grid_and_motion | Pass live normalized tuning to shared MatrixSimulation |
| Appearance | Are heads, pulse and color correct? / head_and_pulse, appearance | Pulse before highlight; sRGB conversion; no revival; TV clock exposure stays distinct |
| GlyphResources | Which glyphs are shown? / resources | Dynamic PUA or classic repertoire; bounded mirrored atlas; notices bundled |
| ClockMask | Does rain stay fixed? / clock | Mask samples entire glyph centers; bounded drift and cache invalidation |
| Settings | Can a remote reach and edit every setting? / remote_settings | Native focus, scrolling, live preview, reset confirmation, localized accessibility |
| Lifecycle | Who owns drawing and idle prevention? / lifecycle, platform_boundary | One renderer; scene/pause/teardown handling; no desktop or agent integration |

[macOS/TV parity matrix](../../tvOS/parity.md) lists deliberate platform differences.
[Current dated validation](validation/2026-10-21-parity/README.md) records source/map
identities and separates checks from remaining physical-device/VoiceOver acceptance.
