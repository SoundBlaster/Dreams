# Prominent preview playback — 2026-10-19

Runtime `ac6906c90366c1cbfc7aeabc5ab1c9a8592586e1`. [Source/map identity](../../evidence/2026-10-19-playback-button/source-identity.json).

Remove the Live Preview heading and its full-width glass panel. A trailing native
button remains, using large control size and fixed64×28pt icon content so Play/Pause
retain the same width. macOS26 uses glassProminent, macOS15 borderedProminent.
The root active-rain tint applies; there is no new color preference. Native
localized accessibility labels and the existing playback identifier remain.

Host draft.16 updates material_composition and LivePreview properties; stable
preview_playback/preview_scale/independent_preview and parent one_settings_owner
obligations remain. Provider, renderer, preferences and lifecycle unchanged.
Prior help-width and sidebar screenshots remain historical evidence.

Release build passed (11.45s), SDK27/minos15 via repository helper on verifiedTB5.
Unit tests do not prove button geometry; bounded actual QA covers native button
size, tint and explicit playback. macOS15/full VoiceOver/default-on remain unproven.

[Structural log](structure.log): HC parse, legacy/native profiles and SpecPM passed
(exit0). Known external capability warnings remain descriptive-draft dependencies.
Hypercode SHA256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`; specpm 0.2.0.
All57 current source/map and snapshot identities match.

## Actual700×600 UI

[Playing](playing.png), [Paused](paused.png): no heading panel, one prominent
green tinted glass button at the top trailing edge. Screenshot bounds remain
approximately184×80 backing pixels in both states at scale2 (92×40 points);
AX labels switch Pause→Play→Pause. Play was restored. AX exposes no geometry,
so size is visually measured, not an AX frame assertion. Temporary sizing harness
was restored byte-for-byte (source and normal binary), production prefs untouched.
