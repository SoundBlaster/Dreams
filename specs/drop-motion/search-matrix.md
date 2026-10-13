# Glyph search claims

All claims in dreams.rain.search_occupancy are descriptive drafts.
User intent is simultaneous minimum occupancy, explicitly replacing starts-per-second semantics.

| Claim | Owner / evidence | Limit or decision |
| --- | --- | --- |
| simultaneous_share | Population + Quota; model tests across five fractions and one/nine columns | Counts live cells, including faint fading ink and heads; assumes >=2 glyph designs |
| tuning | Controller/model normalization, native slider and persistence | Default 10%, ceiling, 0–100 range are implementation choices |
| burst | Independent per-position bursts, global timestamp order | At high occupancy a completed position may immediately restart; activity changes cadence only |
| ink_lifetime | Expiry/overwrite/hide cancellation and no-flash invariant | No lifetime extension or resurrection; new writing pass may own the same coordinate |
| independent_motion | Separate search PRNG; 0/100 comparison and fine/coarse comparison | Fixed activity/coverage inputs; historical pre-feature PRNG digest not reused |
| parent_assembly | Controller, GUI, RainRenderer and both MatrixRain paths | Source review for reset/new renderer/MCP; native execution for slider/persistence |

Zero population, one-cell rounding, partial fraction, saturation, reduced quota, hidden column,
expired one-shot packet and frame subdivision are represented by model scenarios.
Shader/atlas appearance and acquiring agent activity remain outside this boundary.

Current search FSD/P2 source and checks: [2026-10-14 validation](validation/2026-10-14-search-fsd/README.md). Quota/count caching and timestamp queues preserve visible-state digests; prior evidence remains historical.
