# Shared reader impact — 2026-10-23

Runtime source: `680833b15edb0435c31bf3f4f1bc3c17ca934dd5`.
Affected claims: dreams.rain.drop_motion, dreams.rain.search_occupancy, dreams.rain.head_visibility and dreams.rain.glyph_pulse.

[Shared execution and integrity evidence](../../../performance/validation/2026-10-23-shared-reader/README.md)
separates source/thread observations, functional/offscreen tests, paired window
measurements and structural checks. [Pinned input](../../evidence/2026-10-23-shared-reader/source-identity.json)
refreshes this package's affected renderer/reader dependencies without promoting
historical tests or visual observations to this runtime.

Stable claim IDs and requirements remain applicable. Motion/search/head/pulse
formulas, simulation seed, color math and preview viewport/playback/visibility
code are unchanged. Renderer feed input now comes from a shared reader and
per-renderer event deduplication is retained. A renderer keeps its lease across
atlas replacement; releasing the preview renderer also releases that lease,
while another consumer can keep the shared observer active.

Five primary paired runs establish off-main mailbox reads and lower delivery
p95 in this fixture. Rare >50 ms presentation gaps occurred only after the
change and repeated in a separate quiet diagnostic; cadence acceptance remains
open. Structural success is separate from behavior and owner acceptance.
Physical overlay, multi-display, complete-text/pixel latency and tvOS performance
are not established by these tests. No numerical performance budget is accepted.
