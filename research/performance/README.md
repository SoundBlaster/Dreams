# Performance probes

The [measurement plan](../performance-measurement-plan.md) governs this work.
This first implementation measures a bounded **macOS windowed production renderer**,
with no renderer optimization. It is not the native settings window or fullscreen
overlay compositor, and it does not establish tvOS performance.

## Run

Build Release through `make app`. On Egor's host apply the TB5 preflight first;
`scripts/swift-macos.sh` accepts `DREAMS_SWIFT_SCRATCH_PATH` and
`DREAMS_SWIFT_CACHE_PATH`. Route `dist` to a checkout-specific TB5 location when
using the app build entry point. The source checkout remains in place.

```sh
python3 scripts/run-performance.py \
  --scenario research/performance/scenarios/dense.json \
  --output /absolute/new/report-directory --runs 5
python3 scripts/summarize-performance.py /absolute/new/report-directory
```

`--smoke --runs 1` uses 1 second of warmup and 3 seconds of collection. It verifies
the probe only and is explicitly marked smoke, never baseline. Normal fixtures
use 30 seconds of warmup and 60 seconds of measurement. Existing output
directories are rejected to preserve evidence.

Each child gets a new empty mailbox, so no real agent messages are read or pruned.
The diagnostic route executes before preference migration and the production
delegate; no saved settings, overlay or hooks are changed. The probe uses fixed
JSON tuning, the production default simulation seed `0xD2EA5EED`, elapsed monotonic
time, steady demo activity and one Metal surface. It exits after a bounded period.
Closing its window aborts the measurement.

Stop any existing Dreams rain through its normal UI before measurement; its high-level
overlay otherwise occludes the probe and adds unrelated GPU load. The probe never
stops the production session automatically. Restore the previous session afterward.

Keep the window visible during collection. Fully occluded windows, incomplete
callbacks, GPU failures and overflow invalidate a run. Partial occlusion and other
applications' load are not automatically excluded; use controlled conditions.
The displayed window is scaled to a convenient size; the specified drawable and
reference dimensions, not its logical window frame, define renderer workload.
`preview-crop` probes cropped geometry only; it is not a settings lifecycle test.

## Meaning of the report

- Raw `submittedAt` is the beginning of CPU draw/submission work, not the command
  buffer commit timestamp.
- CPU spans are elapsed wall time for selected stages; they are not CPU utilization.
  Draw includes drawable acquisition/encoding and can include waiting. Stage sums
  do not cover all work and must not be added to GPU time.
- GPU duration comes from completed command buffers. Missing timestamps remain
  absent, not zero. This measures the complete command buffer, not the halo pass.
- Presentation intervals come from actual drawable presentation timestamps, sorted
  independently of callback delivery. Submitted frames are not presented FPS.
- Buffer counts/bytes count successful application `makeBuffer` results; they are not measured
  allocator calls or driver memory use. Glyph counts are cache misses rasterized
  during the measured frames, not initial atlas construction.
- Samples are retained in bounded memory and exported once after collection and
  callback drain. There is no per-frame file log. Manifest, fixture hash, binary
  digest, source revision/status and all per-run records are retained.
- Constructor duration has uncontrolled OS/compiler caches. It is not proof of a
  cold-start improvement.

No automatic improvement threshold or issue closure is inferred. Compare paired
runs on the same hardware, preserve their spread, and check behavior separately.
Profiling overhead has not yet been established; use Instruments captures for
allocator/memory data and a separate instrumentation comparison before small gains
are accepted.

## Remaining measurement work

- Scripted mailbox contents and event-to-pixel latency for #42/#46.
- Preview reopen/resource lifetime and capture-tool response for #45/#47.
- Fullscreen, multi-display and physical Apple TV Release runs.
- Allocations, memory, power and GPU pass counters using appropriate tools.
- Quantified collector overhead and device-specific budgets after baseline.

The [descriptive probe contract](../../specs/performance/README.md) records scope
and separates source/structural checks from measurement and acceptance.

The first [15-run baseline](../../specs/performance/validation/2026-10-22-baseline/README.md)
retains compressed raw samples and a reproducible summary. The summary script
accepts either `run-01.json` or its archived `run-01.json.gz` equivalent.
