# Absolute timeline experiment — 2026-10-23

The default-off observer and all 30 preregistered runs are complete. Input,
delivery, identity, clock, order and nominal-thermal checks pass. **Host-load
isolation is unverified**, so this is descriptive evidence from an interactive
machine, not an accepted clean performance baseline. Incremental timestamp cost
and the cause of historical long intervals remain unresolved. PR #54 stays draft;
issue #42 stays open. No cadence fix or numerical performance budget is accepted.

## Protocol and environment

The [protocol](../../../../research/performance/timestamp-protocol.md) was fixed
at `58d2097` before collection and is preserved unchanged. Five blocks alternate
implementation order; each implementation uses control1 → timeline → control2.
Every run warms for 30 s and collects for 60 s. All 30 serial runs were retained,
without result-based replacement, from 19:49:23 to 20:34:44 UTC. The runner/documentation
checkout was clean at `fbe54f90b56a5cf84e4d421c83fc7692cc847322` throughout collection.

Both derivatives use the same full feed collector and boundary process CPU counter.
Only absolute command/GPU observation is toggled. No Instruments, builds, tests,
UI captures or independent file work were started by this task during collection;
progress-log reads continued. This does **not** control work performed by other
agents, the owner, the OS or other applications.

After collection, the owner reported another parallel agent likely compiling Rust
and Swift. This is owner-reported context, not a timestamped process trace covering
the experiment. Other-process CPU, scheduling, memory pressure, power/frequency and
GPU/WindowServer activity were not recorded during the runs. A later `ps` snapshot
cannot reconstruct them. Nominal thermal state does not establish an idle host.
The suspected competition is plausible but is not proven to cause any particular gap.

Process CPU counts Dreams work rather than other processes' CPU, but elapsed draw
spans and presentation intervals include scheduling effects; process CPU cost can
also vary with execution/cache/memory conditions. Across runs CPU per recorded
frame varies roughly 3–8 ms and mean GPU duration roughly 2.6–6.2 ms while mean core
instances remain near 14,315. These observations prevent attributing timing changes
solely to the reader or observer. Alternating order reduces some drift; it does not
remove unknown, changing background load. See the prospective
[quiet-host plan](../../../../research/performance/quiet-host-plan.md); no repeat
series was launched after this limitation was identified.

## Source, executable and resources

- Before: synchronous-reader base `29e07eac9ed6f98844bac9e74031cd3be62560ab`,
  diagnostic derivative `f8b2a503c4ca0c76c0621ee315270625a2d590ca`.
  Executable SHA-256 `bd07ce0de6b21f6843b5c727d1822c87deea1575ec679f929d36d3ce3569f6e5`.
- After: shared-reader parent `d12bac86ee02495899c87fa1d9c313bc14332152`
  (runtime `680833b`), diagnostic runtime `58d2097cf51215a088d0e99eb9b71dc7bf8549ff`.
  Executable SHA-256 `f3c8b629b35bbe1970e3c7ff8949972a370c4cf5bf51ef0c7d06167fa435f9b9`.
- Final analyzer `d86b7d2a208a11d74636d554795ba4f14740f653` adds strict alternating
  C/F/C order and nonoverlapping collection-clock gates after collection. It changes
  no runtime, executable or measured statistic. Python tests and full reanalysis pass.
- M4 Pro, `Mac16,8`, 12 CPU cores, macOS 27 build `26A428`, Swift 6.4 / SDK 27.0.
  Reported display 1512×982 points, backing scale 2, maximum 120 Hz; actual dynamic
  refresh/power/frequency state was not measured. Drawable: 1920×1080.
- Original dense fixture and trace unchanged: 160 columns, density 100%, searching
  10%, glow 100%, speed 1, fade 1, pulse 30%, spread 100%, restored glyphs, opaque
  background, same seed; 24 sessions, 12 events and 12 expired files per run.

[Comparison identity](comparison.json) retains fixture, trace and all three resource
hashes. [Current source identity](../../evidence/2026-10-23-absolute-timeline/source-identity.json)
and [source audit](source-audit.json) cover current bindings/maps, byte-identical
observer segments and the full lossless
[before fixture](../../evidence/2026-10-23-absolute-timeline/before-fixture/source-identity.json).
The fixture commit is local; its archived patch plus the identified base preserves
reconstructable source without calling the derivative unchanged `29e07ea`.
[Precollection audit](source-audit-precollection.json) remains historical evidence.

## Results and limits

Across all 30 runs: 54,202 recorded frames, all 360 expected events delivered,
0 unavailable drawables, 0 occluded frames, thermal states `[0]`. All inputs pass
the diagnostic integrity checks. That is not an external-load or acceptance gate.

All 10 timeline-enabled runs have zero >50 ms and >100 ms intervals. The table
contains the five timeline-enabled pairs only. Percentiles are per run, never pooled.

| Pair | Delivery p95, ms before → after | Presentation p99, ms before → after | >50 ms before → after | >100 ms before → after |
| --- | --- | --- | --- | --- |
| 1 | 1129.206 → 142.667 | 41.666 → 41.666 | 0 → 0 | 0 → 0 |
| 2 | 1032.889 → 132.145 | 33.333 → 33.339 | 0 → 0 | 0 → 0 |
| 3 | 1127.420 → 135.504 | 41.666 → 41.666 | 0 → 0 | 0 → 0 |
| 4 | 1118.812 → 151.885 | 41.666 → 41.666 | 0 → 0 | 0 → 0 |
| 5 | 746.374 → 218.933 | 41.666 → 41.666 | 0 → 0 | 0 → 0 |

Delivery p95 is lower after in all five observed pairs (746–1129 ms before,
132–219 ms after). This is a delivery-to-presented-letter proxy, not complete-label,
pixel or physical-display evidence. The series does not establish a clean-host
speedup estimate or eliminate unobserved confounding.

Across **all 30 runs**, one >50 ms interval occurs: **74.999333 ms in
`01-after-control2`, timeline disabled**, between frame IDs 788 and 789.
No interval exceeds 100 ms. [Exact samples](untimed-control-gaps.json) retain draw,
GPU-duration and presentation observations. Absolute commit/GPU clocks are absent
in this control, so no queue/post-GPU-stage or external-process attribution follows.
The original five gaps stay unresolved; absence in the ten timed runs does not
prove that timestamps prevent gaps or that the reader regression is resolved.

## Incremental observation cost

CPU milliseconds per **recorded frame**, not elapsed time and not simulation-only
CPU. Signed delta = timeline minus mean(control1, control2); control spread is the
absolute difference of the controls, not a confidence interval or noise subtraction.

| Block | Variant | Control 1 | Timeline | Control 2 | Signed delta | Control spread |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | before | 6.922138 | 6.480774 | 7.186034 | -0.573312 | 0.263896 |
| 1 | after | 3.483883 | 3.613271 | 3.585090 | +0.078785 | 0.101207 |
| 2 | before | 3.358915 | 3.252112 | 3.271380 | -0.063035 | 0.087535 |
| 2 | after | 3.580472 | 3.538133 | 3.260152 | +0.117821 | 0.320321 |
| 3 | before | 7.116483 | 7.325366 | 7.234482 | +0.149884 | 0.117999 |
| 3 | after | 7.602397 | 7.830182 | 7.698834 | +0.179566 | 0.096437 |
| 4 | before | 6.720666 | 7.759518 | 7.333089 | +0.732641 | 0.612423 |
| 4 | after | 7.802432 | 7.521117 | 7.510861 | -0.135530 | 0.291571 |
| 5 | before | 7.661667 | 7.492581 | 7.542130 | -0.109317 | 0.119537 |
| 5 | after | 7.613601 | 7.934795 | 7.825721 | +0.215134 | 0.212119 |

Before: median signed delta −0.063035 ms, range −0.573312 to +0.732641 ms;
maximum control spread 0.612423 ms. After: median +0.117821 ms, range −0.135530
to +0.215134 ms; maximum control spread 0.320321 ms. The estimates change sign
and coexist with substantial host/time variation. Cost is **unresolved**, not zero;
negative values do not establish acceleration. No total CPU improvement follows
from between-variant values. Common collector, callback-capture/branch/sample-layout
and process-CPU-observer cost is shared by controls and excluded from this toggle
comparison. No baseline correction or numerical acceptance budget is inferred.

API commit entry/return form a bracket rather than exact driver enqueue. Signed
lower GPU-wait bounds preserve GPU overlap with API return. Every timed frame has
valid absolute clocks; drawable presentation remains distinct from physical scanout.
No timed long gap exists here to diagnose with these new spans.

## Verification and specification impact

- Both derivatives built as Release with repository `make app`; outputs/caches stay
  in their separate TB5 roots. The first before packaging attempt failed because the
  external `dist` target directory did not yet exist; compilation succeeded. Creating
  that directory and rerunning succeeded. The failed log is retained.
- After runtime `58d2097`: default Swift suite reports 84 tests / 21 suites, including
  opt-in Metal early-return cases. Separate `DREAMS_TEST_METAL=1` selection reports
  41 tests / 9 suites and overlaps the default suite; do not sum them. Isolated feed
  input, no installed app replacement or preferences migration.
- Before derivative `f8b2a50`: 9 `RainPerformanceTests` pass. Three 1 s / 12 s smokes
  (before-on, after-on, after-off) validate schema/clock/default-off/export/delivery
  behavior and are retained separately; they are not baseline measurements.
- Four cadence tests with subcases include overlap, invalid clocks, mixed identities,
  incomplete/reordered/overlapping blocks and signed costs. Existing report,
  calibration and eight feed tests plus Ruff pass at final analyzer `d86b7d2`.
- Exact test commands and exit codes are in [test commands](test-commands.json).
  [Logs](logs) retain builds, failures, tests, initial lint/spec checks and collection.
  Final docs/structural checks are recorded separately in `checks.json`.
- `dreams.performance.measure` retains isolation/observation/lifetime/provenance/
  calibration/feed_observation/feed_comparison and adds absolute_timeline and
  timeline_calibration in FrameCPU/GPUCompletion/Presentation/Calibration/ReportExport.
  Optional schema-4 fields are backward-decodable; normal app launches have no recorder.
- Stable drop_motion/search_occupancy/head_visibility/glyph_pulse and settings
  preview_scale/preview_lifetime/preview_playback requirements remain unchanged;
  affected renderer dependencies are refreshed. `dreams.feed.read` and parent ready-input
  assembly still apply; no reader, motion, UI or overlay/capture algorithm changed.
  TV, hooks/MCP producer behavior and physical multi-display acceptance remain outside
  this experiment. Draft structural validity and tests do not accept performance.

## Reproduction and acceptance

[Archive integrity](archive-integrity.json) records raw and stored byte digests for
all 30 reports, three smokes, manifests, inputs and logs. Raw `run-01.json` is stored
losslessly as `run-01.json.gz`; manifests retain original collection paths and hashes.
Run from the checkout root (Python bytecode cache uses the task's TB5 path):

```sh
rtk proxy env PYTHONPYCACHEPREFIX=/Volumes/TB5/Developer/Builds/GitHub/Dreams-4b967f9f500c9508/python/bytecode python3 scripts/analyze-cadence.py specs/performance/validation/2026-10-23-absolute-timeline/runs
```

Output reproduces [comparison.json](comparison.json). [Quality rows](quality.json)
include all controls as well as timed runs; a zero timed-gap count must never be
reported as zero gaps in the complete series. Acceptance remains with the owner.
Next bounded step: agree a quiet-host window and preregister external-load recording
and contamination rules before collecting another performance comparison. The current
series stays preserved as externally uncontrolled evidence; do not discard slow
runs, stop unrelated tasks, close #42 or mark #54 ready based on it.
