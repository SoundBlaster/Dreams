# Fixed synthetic mailbox baseline — 2026-10-23 UTC

Descriptive measurement evidence for [#42](https://github.com/SoundBlaster/Dreams/issues/42).
No feed optimization or issue closure is included. All five frame runs and all
60 expected events passed their separate validity checks. The 12 expired files
were pruned in every run; each final mailbox contained the 24 active sessions.

## Identity and conditions

- Runtime and runner checkpoint: `29e07eac9ed6f98844bac9e74031cd3be62560ab`.
  Application sources are byte-identical to the prior `37a61f8` checkpoint used
  for the Release build; the intervening commit fixes only the external Python
  clock and its protocol/test. Source identities and snapshots are retained in
  [performance](../../evidence/2026-10-23-feed/source-identity.json),
  [motion](../../../drop-motion/evidence/2026-10-23-feed/source-identity.json) and
  [settings](../../../settings-host/evidence/2026-10-23-feed/source-identity.json).
- Release executable SHA-256: `0ed7e6fa955d99f4c64b1983cfbad1ff40e8cad156bd652aa30abf500dfb561e`.
- Apple M4 Pro / Mac16,8, 12 logical processors; macOS 27.0 (26A428), Swift 6.4,
  SDK 27.0. Display reports 1512×982 points, scale 2, maximum 120 Hz; this does
  not establish instantaneous refresh. Runner used Xcode Python 3.9.6.
- One windowed production renderer, 1920×1080 drawable/reference, 160 columns,
  density 100%, searching 10%, glow 1, speed 1, fade rows 1, pulse 0.3,
  brightness spread 1, restored glyphs, opaque background. Preferred 30 FPS.
- Five serial 30 s warmup + 60 s collection runs, fixed default seed and real
  elapsed clock. Forced steady activity is common to all runs. The fixed
  [protocol](../../../../research/performance/feed-protocol.md),
  [scenario](runs/scenario.json) and [trace](runs/trace.json) preceded collection.
- 24 synthetic sessions are populated during warmup. An external process then
  atomically publishes one event per session for 12 sessions at fixed offsets;
  repeated Latin/Cyrillic/command labels exercise cold/repeated letter preparation.
  Twelve expired files arrive at collection offset 20.35 s. This does not exercise
  the complete hook/MCP publisher path, maximum JSON size or lock contention.
- All recorded thermal states were nominal (0). Installed Dreams was closed
  before collection and left closed. No builds, tests, screenshots or profiler
  captures ran during the main series. Light source/documentation work occurred
  on this interactive host and is an uncontrolled load, including filesystem work.
  No cache flush or cold-storage control was performed.

## Results

Times are milliseconds. Each row is one run, not a pooled percentile. With only
12 events, nearest-rank p95 is the maximum event latency for that run. The event
latency uses the conservative atomic-rename-start bound.

| Run | Snapshots on main thread | Snapshot p95 / max | Draw p95: refresh / other | Event latency p50 / p95 | Presentation p99 | >50 / >100 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 59 | 3.173 / 4.311 | 10.200 / 8.149 | 232.3 / 835.4 | 41.666 | 0 / 0 |
| 2 | 59 | 2.411 / 2.767 | 9.129 / 7.476 | 374.6 / 874.4 | 33.333 | 0 / 0 |
| 3 | 59 | 4.018 / 5.206 | 10.388 / 8.314 | 286.8 / 815.8 | 41.666 | 0 / 0 |
| 4 | 59 | 2.775 / 3.866 | 9.821 / 7.283 | 222.5 / 688.6 | 41.666 | 0 / 0 |
| 5 | 59 | 2.626 / 3.919 | 9.880 / 7.243 | 260.2 / 752.9 | 41.666 | 0 / 0 |

All 295 snapshot attempts succeeded on the main thread. Observed presented FPS
was 29.996–30.000. Every run rasterized 28 new glyph tiles during collection.
Per-run read-latency p95 was 594–780 ms, whereas successful snapshot API p95 was
2.41–4.02 ms. Read-to-presented-letter p95 was 94–161 ms. **Inference:** the
one-second polling phase dominates delivery latency in this fixture; these data
do not establish a high-impact frame hitch on this Mac. Refresh/other draw groups
are observational, not a causal A/B experiment.

The measured main-thread work and slow delivery justify evaluating a background
shared feed, but the proposed implementation still needs an identical-fixture
comparison. No filesystem I/O has yet been removed from the production frame path.

## Meaning and limits

- Snapshot spans wrap the production `KeywordFeed.snapshot()` call: lock, directory
  traversal, reads/decoding and pruning are present by source inspection. These
  are API wall spans, not syscall counters or a filesystem trace. Failed attempts
  remain distinguishable; none occurred in this fixture.
- Delivery is the earliest actually presented successful GPU drawable with a
  stable, positive-alpha, non-space event-letter instance in the viewport. It is
  **not pixel/OCR evidence**, complete-label readability, physical scanout or
  proof that another window did not partly cover the surface. Missing events
  invalidate delivery, not become zero latency.
- Publication records bracket atomic rename, not durable storage. Scheduling
  lateness is retained; maxima were 5.43–6.85 ms per run. The source clock bug in
  the initial smoke attempts was detected and rejected before any publication.
  Python 3.9 `monotonic()` uses a process-relative epoch. The accepted runner uses
  `clock_gettime(CLOCK_UPTIME_RAW)` and verifies the app handshake's host-clock domain.
- The added feed observer's cost is uncalibrated. Prior collector calibration
  remains on its original binary and does not imply zero cost here. No allocator,
  memory, energy, cold-disk, multi-display, fullscreen or physical TV claim follows.
- Normal rain behavior, font assets, simulation formulas and production feed polling
  are unchanged. Event packet IDs and encoding success are retained for diagnostics;
  no new settings or hook/MCP behavior is introduced.

## Evidence and reproduction

[summary.json](summary.json) retains per-event receipt/presentation/publication
brackets and per-run metrics. [derived-metrics.json](derived-metrics.json) adds
read-to-present intervals and observed FPS. [raw-identities.json](raw-identities.json)
verifies decompressed archived bytes against the original TB5 reports.
[Manifests](runs/manifest.json) retain executable/resources/fixtures/trace hashes,
commands, source and working-tree state. The same binary/fixture/trace was used
for all five runs. No run was discarded from this main series.

```sh
python3 scripts/analyze-feed-performance.py specs/performance/validation/2026-10-23-feed/runs
python3 specs/performance/validation/2026-10-23-feed/derive-metrics.py
```

The accepted [smoke](smoke/manifest.json) used 1+12 seconds and two events. Its app
revision is `37a61f8`; its clock-fixed runner bytes match checkpoint `29e07ea`.
[First rejected clock attempt](rejected-clock-1/publish-01.json) and
[second diagnostic attempt](rejected-clock-2/publish-01.json) retain their errors,
logs and manifests; neither published messages or produced baseline evidence.
[Legacy schema-1 smoke](legacy-smoke/manifest.json) and schema-2
[control](calibration-control-smoke/manifest.json)/[full](calibration-full-smoke/manifest.json)
compatibility smokes remain separate from the feed baseline.

## Verification and acceptance

The [command record](validation-commands.json) distinguishes source/measurement,
application tests, offscreen rendering and structural validation. Logs are retained
under [logs](logs/dreams-feed-tests-final.log), with tool identities in
[tools.json](tools.json) and source/map audit in [source-audit.json](source-audit.json).

- Release app build succeeded through the required entry point. SwiftPM and `dist`
  use the verified checkout-specific TB5 paths. Required font generation keeps its
  existing generated-source paths; no bulk cache migration was performed.
- Default Release Swift test completed successfully (runner reports 76 tests in
  20 suites; opt-in UI/Metal tests are skipped in this default invocation).
- A separate isolated-mailbox Metal invocation completed 33 selected tests in
  eight suites, covering head visibility/trials, pulse, transparent fading,
  simulation/search, measurement models and native preview crop/lifetime. These
  are a subset of the suite, not 33 additional distinct default tests or a physical
  desktop/window acceptance run.
- Six Python feed tests cover missing/wrong event IDs, failed GPU delivery,
  expiry, report-mode separation, trace bounds and the shared cross-process clock.
  Existing report/calibration checks remain green.
- Final lint/docs and SpecPM/HC checks are recorded separately. Structural
  validation preserves descriptive draft status and unresolved external providers;
  no accepted performance budget or optimization result is inferred.

| Consumer question | Draft claim / role | Contribution / assembly limit |
| --- | --- | --- |
| Is private input isolated? | isolation / RunLifetime | Initially empty disposable mailbox; synthetic external publisher only |
| What did the snapshot cost? | observation, feed_observation / SnapshotObservation | API wall span and thread identity; no syscall attribution |
| Did each event arrive? | feed_observation / DeliveryProxy | UUID receipt plus actual presentation; stable-letter proxy only |
| Are missing callbacks bounded? | lifetime / RunLifetime | Pause and bounded drain, invalidity preserved |
| Can another run be compared? | provenance / Publication, ReportExport | Source/binary/resource/fixture/trace identity; no unpaired speedup claim |

Owner acceptance remains outstanding. Next: implement a shared background reader,
remove snapshot/pruning I/O from draw, and repeat this scenario with comparable
delivery, cadence and behavior evidence before closing #42.
