# Initial performance baseline — 2026-10-22 UTC

This is descriptive measurement evidence, not an optimization or product acceptance.
All 15 runs passed the probe validity checks. Individual raw samples, manifests,
fixture hashes and run order are retained under [runs](runs/suite.json).

## Identity and conditions

- Renderer source: `6cc029cc0f7755365e97f6a405b44163bc2ece87`, based on main
  `8af63e1fc38fddfcff17dc4499e1f3cb3b84ebf6`.
- Release executable SHA-256:
  `94602f8a1cebfb7385c97243a86c76fdb6fea7266a235b9050558e1a71ec90b9`.
  The build was produced from these runtime files before the source checkpoint;
  full source snapshots and resource hashes preserve their identity.
- Apple M4 Pro, `Mac16,8`, 12 logical processors; macOS 27.0 (26A428),
  Swift 6.4 / SDK 27.0. The display reports 120 Hz maximum, 1512×982 logical
  points and backing scale 2; this does not establish its instantaneous refresh.
- One windowed renderer, fixed 1920×1080 drawable and reference pixels. Its
  convenient 960-point window size does not define the workload. This is not
  the fullscreen overlay or the native settings window.
- Renderer preferred rate is 30 FPS. Each run: 30 seconds warmup, then 60 seconds collection. Five rounds of
  normal, dense and dense-no-glow; order rotates between rounds. Runs are serial.
- Fixed fixtures and production default seed; real monotonic elapsed time, empty
  disposable mailbox, forced steady activity. These are not bit-identical time
  steps or a recorded agent-event replay.
- All recorded thermal states were nominal (0). The owner's existing production
  rain was stopped using its normal Esc action before measurement, without
  changing its saved settings. No builds, screenshots or profiler captures ran
  during collection. Light documentation/interactive host work remained possible;
  this was not a dedicated quiescent measurement host.

Manifests retain dirty-tree state. Changes present during collection were
specification/docs/build-routing artifacts; runtime inputs match the pinned
source snapshots. Artifacts stay pinned to this source after later probe guards.

## Results

Each cell is the **median of five per-run statistics**. Brackets show the minimum
and maximum across runs, not a confidence interval. Percentiles are never pooled
across runs. Times are milliseconds.

| Metric | Normal | Dense 160 columns | Dense, glow 0 |
|---|---:|---:|---:|
| CPU draw p95 | 4.59 [2.07–5.05] | 6.37 [5.72–6.52] | 6.31 [2.87–6.70] |
| Simulation p95 | 1.49 [0.67–1.80] | 1.39 [1.17–1.48] | 1.53 [0.74–1.84] |
| Instance assembly p95 | 2.49 [1.23–2.67] | 4.50 [4.05–4.65] | 4.29 [1.90–4.47] |
| Whole command-buffer GPU p95 | 7.36 [6.97–8.37] | 7.12 [6.92–8.11] | 3.44 [3.08–3.73] |
| Actual presentation interval p99 | 54.17 [50.00–54.17] | 50.00 [50.00–54.17] | 50.00 [45.83–54.17] |
| Observed presented FPS | 28.31 [28.15–28.86] | 28.41 [28.19–28.91] | 28.26 [28.09–29.68] |
| Intervals >50 ms, percent | 1.30 [0.77–1.69] | 0.82 [0.64–1.28] | 1.00 [0.11–1.59] |

One interval exceeded 100 ms (normal, round five); no other run recorded one.
Strict >50 ms counts near a refresh quantum are sensitive to timestamp rounding;
raw intervals remain available. Per-run counts are in [summary.json](summary.json),
and the per-frame reports retain all summary percentiles/maxima and counters.

Disabling glow reduced GPU p95 in every paired round, by 47.7–62.1%. This is a
repeatable workload-cost signal for #41. It is **not** a shipped speedup, a
per-pass GPU measurement, or proof that halo work caused presentation stalls.
Presented cadence did not improve consistently. CPU spans show substantial host
variance; these data cannot justify a small CPU optimization threshold.

Buffer counters record successful application buffer creations and payload bytes,
not allocator events, peak memory or driver usage. Zero rasterization cache misses
after warmup do not measure initial atlas construction or novel agent letters.
CPU spans and GPU duration overlap and must not be added into one frame cost.

## Reproduce the analysis

```sh
python3 specs/performance/validation/2026-10-22-baseline/analyze-suite.py \
  specs/performance/validation/2026-10-22-baseline/runs
python3 scripts/summarize-performance.py \
  specs/performance/validation/2026-10-22-baseline/runs/01-dense
```

[analyze-suite.py](analyze-suite.py) recomputes the archived aggregate from raw JSON
or gzip. [suite-executed.py](suite-executed.py) is the exact archived orchestration
used on this host, with its original output path; it is historical execution data,
not a portable new-run command. Portable commands and fixture semantics are in
[usage](../../../../research/performance/README.md).

## Verification and scope boundaries

- Release app build: exit 0, [build log](logs/dreams-perf-build.log).
- Five new Swift measurement/fixture tests: exit 0,
  [test log](logs/dreams-perf-tests.log).
- Nineteen tests enumerated in seven suites, **including those five**, with Metal enabled:
  head visibility/search, pulse, transparent fading and pixel-exact crop.
  Eighteen test functions ran; the opt-in trail video capture test was skipped;
  exit 0, [regression log](logs/dreams-perf-regression.log).
- `make lint`: exit 0, [lint log](logs/dreams-perf-lint.log).
- `make specs-check` with SpecPM 0.2.0 and the local Hypercode CLI: exit 0,
  [structural log](logs/dreams-perf-specs.log). Draft/external-provider warnings
  remain; structural validity does not accept the draft contract.
- [Valid short smoke](smoke-final/manifest.json) is separate from the baseline.
  The [initial occluded attempt](smoke-initial/manifest.json) is intentionally
  retained as **invalid** evidence: GPU execution without drawable presentation
  must not be accepted as onscreen FPS. The production rain obscured that attempt.
- The later startup/overwrite guards and missing-data summary correction on
  `32ebeb5298f66766cca4673b7b4a905da17e425f` have
  [separate verification](../2026-10-22-probe-guards/README.md).

Instrumentation overhead is uncalibrated. Allocations, resident/peak memory,
energy, per-pass GPU counters, scripted mailbox latency, new-letter bursts,
resource-reopen lifetime, capture-tool response, fullscreen/multiple displays and
physical Apple TV remain **unmeasured**. Search-saturated and preview-crop fixtures
are validated inputs but have no five-run baseline here. No numerical budget is
accepted and no issue #41–#49 is closed by this baseline.

Next measurement step: calibrate collector overhead, then add a fixed mailbox
sequence and Allocations/Time Profiler captures for #42/#44 before optimizing them.
