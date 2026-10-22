# Collector calibration protocol — 2026-10-22 UTC

Status: protocol fixed before hardware collection. This estimates the incremental
cost of the full collector **with a common outer observer**. It does not establish
total observer overhead or justify a zero-overhead claim.

## Comparison

Use the same Release executable, resource digests, scenario bytes, drawable,
default seed, elapsed clock, empty mailbox and steady activity for all runs.
The existing dense fixture specifies 160 columns, density 100%, search 10%,
glow 100%, 1920×1080 drawable/reference pixels. No renderer algorithm/shader changes.

- Control: `renderer.performanceRecorder` stays nil. No per-stage measurement,
  full-recorder samples, GPU completion handler or full presentation handler.
- Full: the current collector is enabled during collection, exactly as before.
- Both: the diagnostic window adds the same bounded outer draw timer, presentation
  callback and process CPU counter snapshots at collection boundaries.

The outer timer includes acquiring the drawable, preparing/submitting the draw and
installing the full collector callbacks when enabled. Process CPU includes work on
other process threads and asynchronous callbacks inside the collection interval;
post-stop drain/export are excluded. It is CPU seconds, not elapsed draw time or
an energy measurement. Dividing by observed draws normalizes different draw counts.
Also retain CPU seconds per elapsed second, presented FPS, interval tails, drops,
unavailable drawables, thermal states and every raw sample.

The common observer attaches to `currentDrawable` before submission. Apple states
that the value stays stable until the view delegate's draw callback returns and
supports multiple presentation handlers. A zero `presentedTime` remains missing;
dropped/unpresented samples are reported, never converted to zero-duration frames.
Sources: [MTKView currentDrawable](https://developer.apple.com/documentation/metalkit/mtkview/currentdrawable),
[addPresentedHandler](https://developer.apple.com/documentation/metal/mtldrawable/addpresentedhandler(_:)),
[presentedTime](https://developer.apple.com/documentation/metal/mtldrawable/presentedtime).

Control reports have no full-collector/GPU samples; they are not GPU-validation
baselines. Generic baseline summarization rejects them and uses the dedicated
calibration analyzer instead. Full runs must have one full sample per outer draw;
controls must have none. Missing CPU counter values invalidate the comparison.

## Schedule and interpretation

Five serial blocks, each **control → full → control**, with 30 seconds warmup and
60 seconds measurement per run (15 runs, approximately 22.5 minutes plus startup).
A separate one-block smoke uses 1+3 seconds and never establishes performance.
Keep one diagnostic window visible; stop the owner's original rain through normal
UI first and restore it afterward. Do not edit settings, capture the screen, build
or run profilers during collection. Record interactive-host limitations.

For each block subtract the mean of the bracketing control metrics from the full
metric. Preserve signed deltas, including negative estimates caused by noise.
Report median/minimum/maximum of **per-block** differences; never pool frame
percentiles or subtract aggregate p95s as an overhead correction.

The absolute before/after control difference is an empirical spread indicator,
not a confidence interval or an upper bound on true overhead. A conservative
positive signal is reported only when all five CPU-per-draw differences exceed
the largest observed control-to-control difference and thermal states stay nominal.
Otherwise report unresolved cost; do not infer zero overhead. Even a positive
signal applies only to this fixture and the common-observer conditions.

## Run and reproduce

```sh
python3 scripts/run-calibration.py --output /absolute/new/calibration-directory
python3 scripts/analyze-calibration.py /absolute/new/calibration-directory
# Wiring/validity only:
python3 scripts/run-calibration.py --blocks 1 --smoke --output /absolute/new/smoke-directory
```

Each process exports after stopping. The runner retains the order, modes, individual
manifests/reports and identities; existing output directories are rejected. The
analyzer rejects mixed binaries/resources/fixtures/devices or inconsistent modes
and keeps unavailable data absent. Successful collection, statistical resolution
and product acceptance are distinct states.

Scope exclusions: common observer's own cost; GPU overhead comparison; memory,
allocator events and energy; agent traffic; fullscreen, native settings lifetime,
multiple displays and physical tvOS. Earlier baseline reports remain immutable;
no calibration estimate is subtracted from their percentiles.
