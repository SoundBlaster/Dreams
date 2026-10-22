# Collector calibration — 2026-10-22 UTC

**Result: incremental CPU cost is unresolved above the observed control spread.**
All 15 runs are valid, all five blocks completed and all recorded thermal states
were nominal. This does not establish zero overhead or an accepted performance budget.

## Identity and protocol

- Measured runtime: `bb400f40a3ee9b950d91c65a19238b78b00108ec`, based on merged
  main `86a1ddb531966716ee0153c05570ec2c02fd3d00`.
- Release executable SHA-256:
  `2ad902ff1e2f404c7d511e2ffbdcd09e47dc1df66f957c398b2815d6ef415a95`.
- Apple M4 Pro / Mac16,8 / arm64; macOS 27.0 (26A428), Swift 6.4 / SDK 27.0.
  Recorded display: 1512×982 logical points, backing scale 2, maximum 120 Hz.
  The renderer requests 30 FPS; maximum display refresh is not instantaneous refresh.
- One windowed 1920×1080 drawable/reference, dense fixture: 160 columns, density
  100%, search 10%, glow 100%, speed 1×, fade 1, pulse 30%, brightness spread 100%,
  restored glyphs, opaque. Default seed, real elapsed time, isolated empty mailbox.
- Five control/full/control blocks: 30 seconds renderer warmup + 60 seconds
  collection each. The [protocol](../../../../research/performance/calibration-protocol.md)
  was committed before the first measured run.
- No builds, app tests, profilers or screenshots during collection. Light source/docs
  work and host interaction remained possible. This was not a dedicated quiet host.
  The installed application was closed during the main series; no user setting was
  manually changed. Its original closed state was restored before collection.

All runs use one executable/resource/fixture/device identity. Per-run metadata,
raw samples and actual ordering are under [runs](runs/suite.json). Source, binary
and map identities are separate; dirty documentation is recorded in manifests.

## Primary result

CPU values below are **process CPU milliseconds per observed draw**, including
asynchronous work inside collection. They are not wall-clock draw p95 or GPU time.
Each estimate is full minus the mean of its bracketing controls. Signed estimates
remain signed. Control spread is the absolute difference between those controls.

| Block | Mean of bracketing controls, ms/draw | Full, ms/draw | Difference, ms/draw | Control spread, ms/draw |
|---|---:|---:|---:|---:|
| 1 | 7.576 | 7.492 | -0.085 | 0.198 |
| 2 | 6.878 | 6.813 | -0.065 | 0.251 |
| 3 | 7.526 | 7.927 | +0.401 | 0.379 |
| 4 | 7.118 | 7.466 | +0.348 | 0.517 |
| 5 | 7.024 | 6.951 | -0.073 | 0.330 |

Median paired difference: **−0.065 ms/draw**, range **−0.085 to +0.401 ms/draw**.
Median absolute control spread: **0.330 ms/draw**, maximum **0.517 ms/draw**.
Three paired estimates are negative and two positive. Negative estimates are not
speedups; neither positive nor negative estimates here resolve the collector cost.
The prespecified positive-signal criterion is false. Control spread is not a
confidence interval or a guaranteed upper bound on true overhead.

A small improvement around tenths of a millisecond cannot be accepted from this
experiment alone. Improve host control and repeat paired measurements before
claiming such CPU gains. No estimate is subtracted from old baseline percentiles.
The full/control group medians must not replace paired differences as an estimate.

## Presentation and scope

Across individual runs, presented FPS was 29.992–30.011 for control and
29.994–30.006 for full. Median presentation-interval p99 was 41.666 ms in both
modes. No sample lacked a presentation timestamp and no drawable was unavailable.
This fixture showed no resolved cadence regression; these observations do not
establish a universal frame budget or fullscreen/Apple TV performance.

Both modes include the same bounded outer observer. Its own cost is excluded.
Process CPU boundary deltas exclude callback drain and export. GPU overhead,
allocator events, memory and energy are unmeasured. Control does not collect full
GPU/stage samples and is not a full GPU-validation baseline. Different observer
and host conditions prevent treating this as a direct repeat of the older baseline.

## Verification and reproduction

[Command exits](validation-commands.json), [tool identities](tools.json),
[final lint](logs/dreams-calibration-final-lint.log) and
[structural diagnostics](logs/dreams-calibration-final-specs.log) retain the actual checks.

[summary.json](summary.json) retains per-run and per-block statistics. Reproduce:

```sh
python3 scripts/analyze-calibration.py specs/performance/validation/2026-10-22-calibration/runs
```

Analysis checkpoint `7479e608be5bd53728eebf78dfd3f375e77360c9` adds stricter hardware
identity validation, named identity fields and distinct invalid/incomplete/insufficient/
thermal states. It changes no application code or measured statistic. The earlier
[analysis](initial-analysis.json) is retained; the measured runtime remains `bb400f4`.
Current bindings reuse byte-identical runtime snapshots and replace only the two
analysis/test snapshots. Source/hash checks are recorded in [source audit](source-audit.json).

- Release build and eight focused Swift tests are retained in logs; final verification
  uses the unchanged application source on the analysis checkpoint.
- Python report/calibration tests cover bracketing arithmetic, negative/missing
  values, insufficient repeats, mixed binary/hardware/fixture refusal and generic
  baseline-summary refusal for calibration inputs.
- [CLI guard checks](cli-guards.json): missing, invalid and ambiguous modes rejected;
  an existing output was preserved. [Executed checks](cli-checks-executed.py).
- [Three-run smoke](smoke/suite.json) is validity evidence only, never performance.
- [Legacy smoke](legacy-smoke/manifest.json) remains valid schema 1 and the ordinary
  summary accepts it. It has no calibration payload.
- Hypercode checks cover default, probe=control and probe=full. SpecPM remains a
  descriptive draft with external-provider warnings, separate from product acceptance.

No rendering algorithm, shader, user settings, overlay lifecycle, integration,
glyph data or tvOS implementation changed. Existing rendering/preview claims keep
unchanged source bindings; historical measurements are not relabeled for a new SHA.

Next measurement: a fixed mailbox sequence and I/O/event-latency evidence for #42,
plus allocation/profile evidence for #44. Numerical CPU acceptance needs stronger
control of measurement variance; this result must not be treated as zero overhead.
