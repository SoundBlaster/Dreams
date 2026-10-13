# Optional drop deceleration

The macOS rain can keep its existing entry speed and slow each new head with
negative acceleration. The option defaults off; its only new numeric control
is a in glyph rows/s² at speed 1× (range -120…0, default -12). At zero the
motion remains constant. A fixed terminal speed of 20% of entry prevents
stalled or reversed columns; this is an explicit implementation assumption.
The existing global speed multiplier continues to scale the simulation clock.

Glyphs stay fixed while the writing head slows. Their captured lifetimes retain
sequential fading from the top; changing acceleration or the option takes effect
at the next packet, preserving the current head and old ink. Event-packet
expiry includes the entire decelerating flight and slower rear. Full density,
full coverage and unattenuated visibility keep active columns filled after
initial fill; activity gating may still rest columns.

Historical braking baseline: `984a8a114dc24a38a79bc042b06c1f195be31d64`.
Current source/test baseline: `3a4ad943d727fb657ac9e3ada28b6e586c0b26e1`.
[Draft contract](specs/motion.spec.yaml), [claim matrix](matrix.md),
[historical identities](evidence/2026-10-13/source-identity.json) and
[validation](validation/2026-10-13/README.md) identify implementation,
checks and remaining limits. HC maps describe composition/profiles; they do
not configure the running app or prove runtime behavior.

The change concerns macOS rain motion. Existing overlay/exit, glyph-editor
contracts and tvOS behavior remain separately scoped. The screenshot-status
fix in PR #18 is independent; this branch starts from main after PR #17.

Current motion FSD source and checks: [2026-10-14 validation](validation/2026-10-14-motion-fsd/README.md). Historical snapshots remain unchanged.

Current integrated baseline: [2026-10-14 motion-stack](validation/2026-10-14-motion-stack/README.md). Prior source/test records remain historical.

## Simultaneous glyph search

The saved Search slider controls the simultaneous share of live glyphs, default 10%.
For N visible non-gap cells the target is ceil(N × fraction); 0% disables search,
100% keeps every live cell searching. Fading/head cells count, expired/hidden cells do not.
Bursts settle without a brightness flash and never extend ink lifetime.
Both preview and live renderers use the setting; changing occupancy leaves motion and ink
lifetimes unchanged because search has its own PRNG. This replaces the former opportunistic
mutation policy: the earlier whole-state PRNG parity sample is historical, not a current claim.

[Search contract](specs/search.spec.yaml), [claims](search-matrix.md),
[current identities](evidence/2026-10-13-search/source-identity.json) and
[current validation](validation/2026-10-13-search/README.md) cover both capabilities.
They share a package because the simulation, tuning ownership and consumers are shared.
