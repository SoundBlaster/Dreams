# Shared background reader — 2026-10-23

Status: functional candidate; cadence acceptance remains open. Related issue:
[#42](https://github.com/SoundBlaster/Dreams/issues/42). These measurements do not
close it or accept the newly recovered descriptive reader contract.

## Source, environment and protocol

- Before runtime: `29e07eac9ed6f98844bac9e74031cd3be62560ab`; executable SHA-256
  `0ed7e6fa955d99f4c64b1983cfbad1ff40e8cad156bd652aa30abf500dfb561e`.
  Its preserved app bundle was verified before rebuilding the candidate.
- After runtime: `680833b15edb0435c31bf3f4f1bc3c17ca934dd5`; executable SHA-256
  `724dcc43ec2628ec349021e1d73465958fe312ec6e98cf9f3b4e43260647419e`.
  Subsequent changes are specification/evidence documentation only.
- Apple M4 Pro / Mac16,8, 12 CPU cores; macOS 27.0 (26A428), Swift 6.4,
  macOS SDK 27.0. Display 1512×982 points, backing scale 2, maximum 120 Hz.
  All retained primary and supplemental collection thermal states are nominal.
- One windowed renderer; 1920×1080 drawable and reference scene; 160 columns,
  density 100%, searching 10%, glow 1, speed 1, fade 1 row, pulse 0.3,
  brightness spread 1, restored glyphs, opaque background and steady activity.
  Each run has 30 s warmup and 60 s collection, 24 working sessions,
  12 scheduled events and 12 expired fixture files. Actual elapsed time advances
  the deterministic default seed. All runs finish with the 24 live files.
- The [fixed protocol](../../../../research/performance/shared-reader-protocol.md)
  precedes collection. Primary order: AB, BA, AB, BA, AB; A is before.
  Fixture/trace/resource/hardware/OS/display/toolchain identities match across
  variants; source/executable identities are intentionally different and stable
  within each variant. Runtime identity is separate from runner revision.
- Installed `/Applications/Dreams.app` remained closed. No builds, tests,
  captures or profilers ran during the primary collection. Light documentation
  work and uncontrolled interactive-host/storage-cache load remain confounders.
  Supplemental collection had no other agent file/build/test/UI work; ordinary
  OS background work was still uncontrolled. Later compatibility smokes are separate.

## Primary five pairs

Delivery is publication-begin to the first actually presented drawable containing
an encoded stable non-space event letter. It is a delivery proxy, not pixel/OCR,
complete-label visibility or physical scanout latency. p95 uses the same bounded
12-event trace in each run; do not pool events or quantiles across pairs.

| Pair | Delivery p95, ms (before → after) | Main-thread reads | After background reads | Presentation p99, ms | Intervals >50 ms |
| --- | --- | --- | --- | --- | --- |
| 1 | 1052.0 → 143.8 | 59 → 0 | 84 | 41.666 → 41.666 | 0 → 0 |
| 2 | 1060.8 → 165.7 | 59 → 0 | 84 | 41.666 → 41.666 | 0 → 0 |
| 3 | 1062.0 → 160.8 | 59 → 0 | 84 | 41.666 → 41.666 | 0 → 0 |
| 4 | 1077.9 → 177.4 | 59 → 0 | 84 | 41.667 → 41.666 | 0 → 1 |
| 5 | 778.0 → 139.4 | 59 → 0 | 84 | 41.666 → 41.666 | 0 → 2 |

All 120 expected primary events were delivered. Before: 295 synchronous
main-thread reads. After: 420 observed reads, all off main; ordinary draw consumes
cached input. Notification plus fallback reads can exceed the old once-per-second
poll count: this does not demonstrate reduced total I/O, process CPU or energy.
After cached-input stage p95 ranges from 0.0037 to 0.0064 ms across the five runs;
this is an instrumented span, not a calibrated near-zero cost claim.

The source path and read-thread observations support removal of mailbox lock,
traversal, decode and prune work from synchronous `MatrixRain.draw` and
`RainRenderer.draw`. They are not a syscall trace or a guarantee that frameworks
and lazy font rendering perform no I/O. Source of truth: [comparison](comparison.json)
and [raw inputs](pairs/suite.json). Independent `feedReads` retain background
attempts even when multiple complete before a draw; a frame's `feedRefresh`
identifies consumed input, not I/O done by that frame.

Delivery p95 improved in every pair. Presentation p99 remains approximately
41.667 ms, but after had three intervals >50 ms (58.333, 62.500, 95.833 ms),
where before had none. Neither variant had an interval >100 ms.
`longIntervalsDidNotIncreaseEveryPair` is **false**. Unchanged p99 does not erase
this signal; absence of a cadence regression has not been established.

## Supplemental quiet diagnostic

Two additional pairs, AB then BA, were specified after observing the three long
intervals. They are retained separately and do not replace or pool into the
primary five-pair evidence. Each uses the same 30/60 s bounds and identities.
[Executed orchestration](quiet-pairs-executed.py), [run order](quiet-pairs/suite.json)
and [analysis](quiet-summary.json) preserve all four runs.

| Pair | Delivery p95, ms (before → after) | Presentation p99, ms | Intervals >50 ms |
| --- | --- | --- | --- |
| 1 | 1051.0 → 143.6 | 41.666 → 41.666 | 0 → 2 |
| 2 | 1122.3 → 185.1 | 41.666 → 41.666 | 0 → 0 |

All 48 expected supplemental events were delivered; after again reports no
main-thread reads. After had two more intervals >50 ms (54.166, 66.666 ms);
before had none. No interval exceeded 100 ms. With the primary results this is
five long intervals in seven after-runs, zero in seven before-runs. Their cause
is unresolved; neither quiet collection nor temporal overlap establishes causality.

[Long-interval observations](long-intervals.json) retain draw/submission/GPU spans,
glyph-rasterization counts and temporal overlap with reads. None coincided with
new glyph rasterization. Only one overlapped a background read; overlap or its
absence cannot attribute a compositor/GPU/scheduling delay. No Instruments trace
was collected in this pass. Investigating these gaps is the next acceptance task.

## Functional and compatibility checks

Pinned after-source `680833b` was built with `make app` using checkout-specific
SwiftPM/dist outputs and shared supported cache on the verified TB5 SSD; see
[preflight](tb5-preflight.json) and [build log](logs/dreams-reader-build-measured.log).
The existing font-generation entry point still emits its normal intermediate
source artifacts; no cache migration or installed-app replacement occurred.

[Exact test commands](logs/dreams-reader-final-test-commands.json), with
`DREAMS_SWIFT_SCRATCH_PATH` and `DREAMS_SWIFT_CACHE_PATH` routed to TB5:

- Release default suite reports 81 tests / 21 suites passed, including opt-in
  skips represented by early returns. This is not 81 independent executed checks.
- `DREAMS_TEST_METAL=1` selected Release run reports 38 tests / 9 suites passed.
  It overlaps the default suite, and includes two renderers receiving the same
  event plus existing head/pulse/crop/preview checks. Logs:
  [default](logs/dreams-reader-final-default-tests.log),
  [selected Metal](logs/dreams-reader-final-metal-tests.log).
- Reader tests exercise notifications independently of fallback, lock contention
  retaining the cache, expiry without a publisher write, directory replacement,
  last-lease cancellation/restart and deinit cleanup. Existing pixel-exact crop
  assertions remain unchanged; their mailbox fixture is now explicitly isolated.
- Eight feed-analysis tests, existing report/calibration tests, lint and structural
  checks are recorded separately in [local checks](local-checks.json).

The retained initial [compiler errors](logs/dreams-reader-build.log.gz) and
[interim Metal fixture failure](logs/dreams-reader-metal-tests.log) were found
before the measured revision. Directory assignment/async thread probing were
corrected. The parallel crop test had shared an input mailbox; isolating that
input retained its exact assertion, and the final suite passed. Those failures
are development history, not a failing measurement of the pinned executable.

The [feed smoke](smoke-summary.json) has two valid events and 17 off-main reads.
It ran before committing `680833b`, so its manifest stamps parent `61e37d2` with
a dirty worktree; executable/source bytes match the measured candidate, but its
short run is not primary evidence. [Compatibility smokes](compatibility/commands.json)
exercise normal, control and full modes separately after measurement. The first
control attempt is invalid (40 occluded frames) and retained; its one bounded
retry and the normal/full attempts are valid. These 1/3 s probes establish report
compatibility only, not recalibrated overhead or performance acceptance.

## Specification impact and integrity

New draft [dreams.feed.read](../../../keyword-feed/specs/reader.spec.yaml) owns the
ready-input/cache/lease/background/offline-refresh behavior. Performance adds
`feed_comparison` to existing diagnostic claims. Motion/search/head/pulse and
settings preview requirements keep their stable IDs; affected bindings are refreshed.
Overlay/display/capture source, hook/MCP producer semantics and tvOS stay distinct.

[Source audit](source-audit.json) compares 27 retained source entries and reused
binding snapshots with Git `680833b` and current source, checks 12 map snapshot
entries against current maps, and losslessly verifies 15 compressed raw reports
against external originals. [Raw identities](raw-identities.json) retain both
uncompressed and archive hashes. [Tools](tools.json) pin the structural validators.
Structural validation establishes artifact validity, not implementation acceptance.

Reproduction from this checkout (reports can remain compressed):

```sh
rtk proxy python3 scripts/compare-feed-performance.py specs/performance/validation/2026-10-23-shared-reader/pairs
rtk proxy python3 scripts/analyze-feed-performance.py specs/performance/validation/2026-10-23-shared-reader/quiet-pairs/01-after
rtk proxy python3 specs/performance/validation/2026-10-23-shared-reader/audit-evidence.py
```

[Reproduction record](reproduction.json) verifies identical primary comparison
and all four supplemental run analyses. Historical baseline/calibration packets
remain on their own sources. Added feed-observer overhead is uncalibrated.
Allocations, resident/peak memory, total process CPU/energy, cold storage,
fullscreen, physical multi-display/Apple TV performance, pixel/full-label latency
and owner visual/acceptance decisions remain unknown. Issue #42 stays open.
