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
| Packaging | Which Apple TV app and local artifact are built? / store_packaging | Registered TV identity, independent version/build, TV artwork and privacy manifest; local export is distinct from distribution and acceptance |

[macOS/TV parity matrix](../../tvOS/parity.md) lists deliberate platform differences.
The [App Store target baseline](validation/2026-10-25-store-target/README.md) covers
the registered identifier, local signed export, artwork, privacy and packaged
resources separately from distribution, rights and physical-device acceptance.
[Remote-input validation](validation/2026-10-21-focus-input/README.md) records source/map
identities and separates checks from remaining physical-device/VoiceOver acceptance.

[Restored body-spacing validation](validation/2026-10-25-glyph-spacing/README.md)
records common font-body sizing separately from punctuation, classic geometry,
source font editing and physical/film-fidelity acceptance.

[Denser ordinary-body packing](validation/2026-10-25-denser-glyphs/README.md) supersedes the first cap-height fit after owner feedback; historical evidence is preserved.

[90-column defaults and coarse remote steps](validation/2026-10-25-remote-steps/README.md) preserve saved preferences and distinguish model/repeat tests from gesture/device acceptance.
