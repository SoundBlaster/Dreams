# Retained instance storage review — 2026-11-16

Addresses [PR #87's retained-capacity review](https://github.com/SoundBlaster/Dreams/pull/87#discussion_r4586018193).
Base: `c194bd95c757b65d886f7427aa72310bef006eb5`; branch `perf/cpu-gpu-optimization`.
The parent's relative-link fixes are preserved. This is a local follow-up, without
push, review comments, SDK changes or replacement of the installed application.

## Reproduction and metric

The old renderer clears `cells` and `halos` with `keepingCapacity: true`; its
inactive-grid return happens before either clear. Thus an empty or much smaller
frame still retains the large frame's backing storage.

The new opt-in Metal test drives the real MatrixRain with an isolated feed and
completed offscreen command buffers. It warms a 240×427 grid (102,480 instances
per pass), then independently exercises a 24×14 grid, Glow=0, or idle intensity=0.
It also checks a nearby 239×425 resize, repeated frames, repeated inactive/off
frames, reactivation and re-enabling glow. Before the fix, the eight requested
trim assertions fail while the test finishes and records all baseline snapshots.

**Metric: `Array.capacity × MemoryLayout<MatrixRain.Cell>.stride`**, summed across
the two arrays. Stride is 48 bytes. This measures reserved CPU element storage;
it excludes Array/allocator headers, GPU copies, other objects, allocator page
caches, resident/peak memory and process RSS. Do not interpret it as an equal
reduction in process RSS. A read-only diagnostic returns capacities and opaque
integer buffer identities without retaining Array aliases. It is not called by
production drawing or added to the existing performance collector.

| State after transition | Before, retained element bytes | After, retained element bytes |
| --- | ---: | ---: |
| Large 240×427, Glow=1 | 14,417,856 | 14,417,856 |
| Nearby 239×425 | 14,417,856 | 14,417,856 |
| Small 24×14 | 14,417,856 | 77,712 |
| Large grid, Glow=0 | 14,417,856 | 6,029,280 (core only) |
| Inactive | 14,417,856 | 0 |
| First reactivated frame, 1,875 instances/pass | 14,417,856 | 507,840 |

In the candidate glow-off run, core capacity stays 125,610 and halo capacity
falls from 174,762 to zero. In the baseline glow-off process those capacity
roundings happen to be reversed; allocator layout is not deterministic. The
important within-run result is unchanged core identity/capacity and complete
halo release. After small resize the observed capacities are 1,023 core and
596 halo elements. Exact allocation rounding is not a portable contract.

## Policy and cost

- On an existing grid-rebuild branch, discard each old array only when its
  capacity exceeds `2 × columns × max(rows, 32)`. The 32-row floor accounts for
  the existing core reservation; twofold slack avoids reallocating on small
  nearby resizes. This is a trim threshold, not a universal allocator/RSS cap.
- Clear halos without retaining capacity when Glow is not positive, matching
  the condition for submitting halo instances. Keep the core buffer.
- Release both arrays on the inactive-grid early return, including subsequent
  inactive frames. Re-enabling activity/glow allocates storage again as needed.

Normal same-grid frames retain capacity. The grid-size comparison already
existed; the extra capacity tests run only inside its structural-change branch.
The steady path adds one scalar Glow comparison to array clearing, with no
per-glyph condition, scan, timer, observer or memory-pressure subscription.
Identity checks cover twelve large steady frames and twelve small steady frames,
plus the nearby resize and the unchanged core on glow-off. Source review confirms
the steady path retains storage; identities alone are not an allocator-event trace.

All changes take effect on the next draw. A paused renderer has no draw in which
to trim. Density changes on a fixed active grid intentionally retain capacity,
and no memory-pressure policy is introduced. Array contents have already been
copied into Metal-owned buffers before the next draw; releasing CPU storage does
not release or overwrite an in-flight GPU buffer. Simulation, feed, atlas,
shader, blending, ordering and cadence policy are unchanged.

## Validation and evidence

Raw evidence is in `artifacts/storage-review-20261116/`: before/after JSON and
BGRA frames, test/build logs, application provenance and bounded performance
runs. The first fixture attempt lacked a feed subscription; it was corrected
before recording the baseline. The subsequent baseline failures are the eight
expected retention assertions, not successful candidate checks.

- Focused test: all three transition cases pass after the fix; **11/11 transition
  BGRA frames match baseline exactly**.
- Release suite with opt-in Metal tests: **116 tests in 30 suites pass**. The
  previous **32/32 replay PNGs remain byte-identical**. Interactive/device suites
  remain skipped; this is not the full `make test`, CI or physical-device acceptance.
- `make app` builds a separate ad-hoc signed Release candidate with the same
  Xcode 27.2 / Swift 6.4.2 / SDK 27.2 setup and macOS 15.0 target as the comparator.
- Short steady-workload guard: two AB/BA pairs each for Glow=0 and Glow=1,
  10 s warmup + 20 s collection, dense 1920×1080 / 160-column fixture. The baseline
  is the preserved shader candidate whose production source matches this base;
  it is not relabeled as a new build. This guard checks obvious CPU/cadence
  regression, not a new performance claim. Results are below.

The previous CPU/GPU speedup results remain historical for their measured code.
They require the added memory qualification: the original capacity-reuse patch
could keep roughly 14.4 MB of element storage per renderer after these transitions.
This fix reduces transition retention; it does not establish lower steady-state
CPU/GPU time, peak/RSS usage or power consumption.

[Specification impact and current bindings](../../specs/performance/validation/2026-11-16-storage/README.md)
separate these observations from official structural validation and acceptance.

## Short steady-frame guard results

All eight runs are valid with thermal state 0, no missing presentations and no
intervals over 100 ms. Values below are medians of two run-level values.

| Profile / metric | Before | After |
| --- | ---: | ---: |
| steady-no-glow: CPU % one core | 28.8266 | 28.7272 |
| steady-no-glow: GPU p50 ms | 0.6258 | 0.6269 |
| steady-no-glow: presentation p99 ms | 16.6809 | 16.6809 |
| steady-glow: CPU % one core | 22.1498 | 22.0614 |
| steady-glow: GPU p50 ms | 3.7814 | 3.7825 |
| steady-glow: presentation p99 ms | 50.0416 | 50.0416 |

No-glow has zero intervals above 50 ms. Glow retains its existing presentation
jitter: counts above 50 ms are 8→17 in pair 1 and 16→13 in pair 2; p99 is
unchanged. Paired CPU differences also change sign. This short guard detects no
consistent CPU/cadence regression, but cannot rule out small timing changes or
quantify transition/reallocation latency. No timing gain is claimed. Host load
is monitored, not controlled; no builds run during collection.

The production LaunchAgent and installed Dreams child are running again, with
manual=false, threshold 300 s and a visible session. Configuration hashes match
the start of this follow-up. launchctl reports a previous exit status of 1 while
the current controller/child run; the already-known external controller failure
path is outside this source change. Installed and candidate signatures verify.
The separate candidate is `artifacts/storage-review-20261116/candidate/Dreams.app`.
No installed application, other service, hook configuration or VM was modified.
