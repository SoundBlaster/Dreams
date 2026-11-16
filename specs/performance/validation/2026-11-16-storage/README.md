# Retained instance storage — 2026-11-16

Base `c194bd95c757b65d886f7427aa72310bef006eb5` plus the
[dated source/map hashes](../../evidence/2026-11-16-storage/source-identity.json)
identifies this tested overlay. Historical snapshots and validation stay tied to
their old sources. See the [review investigation](../../../../research/performance/2026-11-16-instance-storage.md).

## Impact assessment

Only macOS MatrixRain CPU instance-storage lifetime changes. Trim on an existing
grid rebuild when capacity exceeds twice the new grid/reservation need, release
halos on a Glow-off draw, and release both arrays before the inactive return.
Ordinary frames retain capacity. A diagnostic snapshot returns only integers;
it is outside production drawing and does not redefine performance-probe counters.

- `dreams.rain.drop_motion`: deterministic_timing, grid_rebuild_clock,
  tail_lifecycle, stable_packet, bounded_event, parent_assembly remain unchanged.
  The arrays contain derived render instances, not simulation state.
- `dreams.rain.search_occupancy`: simultaneous_share, tuning, burst, ink_lifetime,
  independent_motion and parent_assembly keep the same scheduling and glyphs.
- `dreams.rain.head_visibility` and `dreams.rain.glyph_pulse`: appearance,
  independent phases, off/lifetime and parent assembly use unchanged fragment,
  opacity and instance math.
- `dreams.rain.frame_budget/glow_frame_rate` and `invisible_halo_floor` are
  unchanged. Releasing an unused halo array does not change its coverage floor.
- `dreams.feed.read`: snapshot, freshness, error, lifetime and assembly claims
  keep the same reader/lease behavior. The new test uses its own leased feed.
- `dreams.performance.measure`: isolation, observation, provenance and calibration
  are unchanged. The existing probe still does not measure RSS/allocator events;
  separate Array capacity observations are explicitly scoped as element storage.

Overlay per-display ownership, preview ownership and FPS reservation are revisited:
cleanup executes on the next draw, never touches already-copied Metal buffers,
and permits later activity/glow to allocate again. Paused-view and memory-pressure
handling are not newly covered. The 2× threshold is an implementation choice,
not a newly accepted product memory budget. HC role/profile/claim semantics do
not change, so maps are hashed without cosmetic edits. tvOS code and shader source
are untouched; no TV evidence is inferred. All contracts retain draft acceptance.

Current full-file MatrixRain bindings are refreshed in drop-motion, frame-budget,
keyword-feed and performance. Prior CPU/GPU figures remain historical; the new
memory caveat must accompany capacity-reuse claims. Complete renderer/atlas,
controller, process-memory and platform lifecycle coverage remains backlog.

## Checks and limitations

The focused baseline has eight expected retention failures; the candidate passes
three transition cases. All 11 transition pixel buffers and 32 existing replay PNGs
are byte-identical. Final opt-in Release suite: 116 tests in 30 suites pass, with
interactive/device suites skipped. Local build, bounded cadence guard and raw
evidence are described in the investigation; numerical timings are not acceptance.

Required skills `legacy-to-specs`, `hypercode-architecture-map`,
`specpm-legacy-boundaries`, `specpm-author-spec`, `specpm-review-spec`, `no-wait`
and tools `rtk`, `hypercode`, `specpm` remain unavailable after checking the local
skill roots and executable paths. Official HC parse/profile and SpecPM validation
are pending for the affected packages/maps and dependent overlay/preview/FPS
assemblies. Generic YAML and documentation checks do not substitute for them.
Source review, app/Metal tests, measurements, structural validation and acceptance
are recorded separately; no release, fullscreen or physical-device claim is made.

Evidence: [capacity observations](memory-summary.json), [pixel identities](pixel-comparison.json),
[steady-frame guard](summary.json), [commands/exit codes](checks.json),
[candidate provenance](candidate-provenance.json), [baseline observer](baseline-observer.json),
[restoration](restoration.json) and [local raw hashes](local-evidence-manifest.json).
All eight bounded guard runs are valid. CPU differences change sign between pairs;
GPU p50 and presentation p99 remain essentially unchanged. Glow's pre-existing
long intervals remain on both sides. This is a regression guard, not a new speedup
or cadence/power guarantee. Installed app/configuration preservation is separately
verified; official structural checks are still not passed.
