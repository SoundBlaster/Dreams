# Absolute command/GPU timeline experiment — 2026-10-23

Pre-collection protocol for the next bounded diagnostic. The previous five
unprofiled gaps and three native trace observations remain on their original
sources. These new diagnostic derivatives cannot retroactively give them missing
GPU timestamps. No production algorithm/presentation synchronization changes.

## Implementations and observation

- Before: source base `29e07ea` (synchronous per-renderer feed poll) plus the
  common timestamp/CPU-observer patch. The derivative has its own Git identity,
  executable hash, full source/patch evidence; do not label it unchanged `29e07ea`.
- After: source base `d12bac8` (shared background reader, runtime `680833b`) plus
  the same timestamp/CPU-observer behavior, with its own source/executable identity.
- Preserve command API-entry and return timestamps, absolute command-buffer GPU
  start/end, and existing drawable `presentedTime`. Commit is a bracket, not an
  exact driver enqueue time. A GPU start before API return is legitimate: preserve
  signed lower queue-wait bounds instead of clamping them to zero.
- Default-off observation is selected only for the isolated feed diagnostic by
  `DREAMS_PERF_TIMELINE=1`. Timeline-enabled reports use schema 4 and an explicit
  mode; legacy missing optional fields remain decodable. The ordinary app has no
  enabled recorder. API duration/absolute-clock availability is validated separately.
- Sample collection process CPU at collection entry/exit for all these feed runs,
  identically on/off and before/after. The original full collector, callback capture,
  common branch/CPU-observer cost are not calibrated by the on/off comparison.

## Fixed workload and order

Use the original dense fixture/trace unchanged: 160 columns, 1920×1080 drawable,
100% density, 10% searching, same seed/resources/settings, 24 sessions, 12 events
and 12 expired files. Every run has 30 s warmup and 60 s collection. No Instruments,
UI captures, builds, tests or independent file work during collection. Installed
Dreams stays closed; the interactive OS background remains uncontrolled.

Five blocks. For odd blocks, before then after; for even blocks, after then
before. Each variant runs **control1 → timeline → control2**. All three use the
same executable and full feed collector; only timeline field collection/extra
commit-clock reads differ. The timeline runs form five before/after pairs, with
controls retained as bracketing input. Thirty serial runs require 45 minutes of
warmup/collection, plus launch/export overhead. No result-based replacement.
Invalid frame/delivery/identity/clock/thermal input stays retained and prevents a
complete comparison; do not silently drop it or substitute another run.

## Analysis and evidence limits

- Require all 30 slots, matching fixture/trace/resources/hardware/OS/display/SDK,
  stable per-variant source/executable identity, nominal thermal state, all expected
  events and expiry. Preserve both parent source bases and both derivative identities.
- Incremental CPU cost for each block/variant is signed timeline cost per draw minus
  the mean of its two controls. Report each delta and control spread, keeping negative
  deltas. Compare them descriptively: unresolved above noise is not zero overhead.
  Do not infer a numerical acceptance budget or total collector cost.
- For each of five pairs retain delivery p95, presentation p99, >50/100 ms counts
  and every long interval's preparation/commit/GPU/post-GPU spans. Never pool
  percentiles or rewrite old baseline records. The signed lower bound can be
  negative because GPU execution may overlap the API call; upper/lower refer to
  the call bracket, not a measured driver enqueue event.
- Presentation remains the drawable timestamp, not physical scanout; no fullscreen,
  multi-display, TV, energy, allocation or pixel/full-label acceptance follows.
- No automatic fix selection, issue closure or PR #54 readiness. Choose a remedy
  only from the observed stage and matching controls; a descriptive diagnostic may
  remain inconclusive while still preserving a reviewable result.
