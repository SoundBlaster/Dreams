# Denser restored TV glyphs — 2026-10-25

Runtime/test source `8830eab2fc5361d1b154a5969d072fe15da579d2` follows
`d9b25326f0f901a1da7142accd1388f2f05c14b9`. The owner rejected the first
simulator screenshot as too loose and asked for almost touching glyphs.
This revision continues the inferred vertical-TV scope; horizontal packing
and macOS geometry are not separately redesigned. The film frame remains a
qualitative reference, not a measured fidelity target.

## Implementation and measured geometry

The common uniform XY factor grows another12%, to1.1995935 relative to the
original renderer. The nominal cap body spans1.12 rows; natural full-body
overshoots may overlap slightly. No per-glyph fitting, contour/font edits,
atlas crop changes, new instances, grid/preferences or timing changes occur.
Classic stays at scale1. FPS inherits the active atlas factor with fixed cell
centers. Shared FPS source is unchanged, so its earlier macOS checks remain
historical checks, not new executions at this revision.

The actual Metal atlas/production-quad test now measures all22 ordinary
G01...G22 bodies, separately from later short marks. At alpha threshold32,
21/22 cover at least1.01794 rows; the shortest is0.848284. The lower quartile
is1.074493, G21 is1.1310455 and G25 punctuation stays0.22620909. The longest
body reaches1.24415 rows. Thus near contact is a repertoire property rather
than an assertion based on a single cap-height character; no exact lack of
pairwise overlap is promised. Aspect, classic sizing and FPS alignment pass.

`make test-tv TV_DEVICE=B29EC156-5EF9-4A56-8147-1C98D4E228DB
TV_DERIVED_DATA=<verified checkout TB5 DerivedData>
TV_TEST_OPTIONS='-parallel-testing-enabled NO'` exits0:21 tests pass,0 skipped.
[test-summary.json](test-summary.json) is exported from the actual xcresult.
Xcode27.1/SDK tvOS27.0, Apple TV4K3rd-generation1080p simulator. Existing
font-registration and repeated-drawable diagnostics remain observations.
SwiftLint strict exits0 with its existing unused_import configuration warning.

Current TV resources/FPS contracts and bindings are refreshed; all IDs and draft
acceptance stay stable. [Source identity](../../evidence/2026-10-25-denser-glyphs/source-identity.json).
Larger quads cost about25.4% more area than the first spacing revision and43.9%
more than the original renderer. No physical Apple TV FPS/GPU-cost, long-run,
font-rights or film-fidelity acceptance follows from these structural/tests checks.
No release, upload or physical installation is performed.

## Visual observation

The delegated Xcode session successfully launched the app and captured hierarchy,
then ended its session. Its first frame was during startup and unsuitable for
packing assessment. Root subsequently captured the populated native1920x1080
rain through simctl without changing preferences. [Full frame](tv-rain-denser.png)
and [detail](tv-rain-detail.png) are the actual screenshot and a nearest-neighbor
2x crop of rectangle(1020,470)-(1270,850), with no color/sharpness/glow edits.
The populated frame was inspected: vertical bodies approach/contact neighboring
rows, while short marks remain short and column gaps remain visible. This is
not a matched-scene comparison or film-fidelity acceptance; the owner must judge
the requested visual density. The clock is active; FPS is absent from this frame.

`make specs-check HYPERCODE=/Users/egor/Development/GitHub/0AL/Hypercode/.build/debug/hypercode`
exits0 with existing provider warnings. `python3 scripts/check-docs.py` exits0
(202 Markdown files); SwiftLint strict and diff checks exit0. Structural validity
is separate from the21 simulator tests and the screenshot observation.
