# Cadence investigation — 2026-10-23

Status: diagnostic progress, **cause of the historical five gaps unresolved**.
[Original before/after evidence](../2026-10-23-shared-reader/README.md) and its
failed long-interval flag remain unchanged. PR #54 stays draft; issue #42 stays open.
No application, renderer, reader, shader, fixture or saved setting changed here.

## Question and retained source

Locate the rare long intervals on the chain from CPU preparation through GPU
queue/execution to the drawable's recorded presentation timestamp. The old report
retains GPU duration, not GPU start/end or queue wait. Its `submittedAt` field
actually marks **draw entry**, not `MTLCommandBuffer.commit`; do not interpret
`presentedAt - submittedAt` as queue latency.

All three diagnostic attempts use unchanged after-runtime
`680833b15edb0435c31bf3f4f1bc3c17ca934dd5`, executable SHA-256
`724dcc43ec2628ec349021e1d73465958fe312ec6e98cf9f3b4e43260647419e`.
The preserved before executable was also rehashed to
`0ed7e6fa955d99f4c64b1983cfbad1ff40e8cad156bd652aa30abf500dfb561e`,
but **no new before run** was collected in this study.
The runner/documentation checkpoint is `38c88041b3741542fb489739a8051cdbe69f8e4c`.

The fixed input is the original 160-column dense opaque scenario: 1920×1080,
density 100%, searching 10%, 24 sessions, 12 scheduled events, 12 expired files,
30 s warmup plus 60 s measurement. Fixture SHA-256 remains
`578acf94702245c6866867690f872db0dd246d48b2c0fb2b4e399c878d202b63`;
trace SHA-256 remains `24c59129d8627bcbbe5900d1077b49c7951056f5af4231595767c57670632328`.
Mac16,8 / M4 Pro, macOS 27.0 (26A428), 12 CPU cores, backing scale 2,
1512×982-point display / maximum 120 Hz. Native trace uses Instruments
27.1 (27A9275), Metal System Trace, attached to the disposable probe only.

## What the original reports establish

[Neighbor windows](historical-gap-neighbors.json) preserve the five original
>50 ms gaps with adjacent submission/presentation timestamps. All three affected
runs have zero duplicate or out-of-order presentation timestamps in submission
order, so these gaps are not an artifact of sorting callback arrival order.

For four of five frames, draw preparation takes about 3–5 ms while the subsequent
draw-end-to-presentation span takes 46–105 ms. The remaining frame has a 20 ms draw
and 34 ms afterward. GPU durations alone do not establish whether their wait was
before GPU execution, after it, or both. Neighboring short intervals after a gap
are consistent with accumulated frames catching up, but do not identify a cause.
The [original read-overlap record](../2026-10-23-shared-reader/long-intervals.json)
still does not establish reader causality.

## All three profiling attempts

The [protocol](protocol.txt), final [executed runner](profile-executed.py) and
per-attempt command/settings manifests preserve failures and changes in capture
bounds. Every application run delivered a frame-valid report, had zero occluded
frames and ended with the 24 active files. These are instrumented diagnostics,
not new paired baselines; profiler overhead remains uncalibrated.

| Attempt | Capture | Application >50 / >100 ms | Trace usability |
| --- | --- | --- | --- |
| [First](after-metal/manifest.json) | Unwindowed, until app exit | 4 / 0 | Saving exceeded the initial flush deadline; interrupted capture failed export with `Document Missing Template Error`; unusable |
| [Second](after-metal-windowed/manifest.json) | 60 s recording, requested 30 s rolling window | 20 / 1 | Saved/exported successfully; seven gaps occur during capture and thirteen after it ends; no native frame join performed for this attempt |
| [Final](after-metal-full-window/manifest.json) | Until app exit, requested 60 s rolling window | 6 / 1 | Saved/exported successfully; actual exported command/GPU coverage matches three of six long gaps |

[Exact recording-boundary calculation](after-metal-windowed/recording-boundary.json)
corrects the initial coarse interpretation of the second attempt: seven gaps are
before recording ends and thirteen afterward. It is incorrect to attribute all
20 to output saving. Neither temporal category alone establishes a cause.

The first save was cut short by this study's runner; its raw files and logs remain
local and it is not treated as a successful trace. The revised runner allows
180 s for finalization. The final attempt saves after application exit, preventing
that save phase from overlapping the application's measurement.

The final trace reports an 88.669 s recording, but exported command-buffer rows
cover approximately trace-relative **58.402–88.566 s**, rather than the requested
full rolling minute. Use actual table bounds, not the requested window setting.
The 117 ms gap at application frame 332 is among those **outside** this exported
coverage. This study cannot assign it to a native stage.

## Native/application join and result

[Analysis code](analyze-native-timeline.py) converts the trace's Mach epoch using
its exported timebase (125/3 ns per tick). Native command-buffer creation must
fall within one application draw interval; frame IDs are unique. GPU intervals
are joined by the same native command-buffer ID and target PID. Across 905 matched
buffers, zero unmatched commands remain and the largest difference between native
GPU span and the application's GPU duration is 0.0272 ms. This cross-check supports
the clock and frame join, rather than relying on nearest timestamps alone.

| Application frame | Presentation interval, ms | Draw, ms | Native commit → GPU start, ms | Native GPU span, ms | GPU end → recorded presentation, ms |
| --- | --- | --- | --- | --- | --- |
| 977 | 54.166 | 5.825 | 0.483 | 6.722 | 35.987 |
| 1277 | 58.333 | 4.133 | 0.587 | 5.851 | 50.939 |
| 1727 | 66.666 | 4.385 | 0.617 | 5.875 | 58.938 |

These three buffers reach the GPU within 0.48–0.62 ms, finish in 5.85–6.72 ms,
and their native completion events follow GPU end by about 0.09–0.13 ms. The
remaining 35.99–58.94 ms precede the application's recorded `presentedTime`.
No observed background read begins within 50 ms of these draw entries.

**Scoped conclusion:** in these three new instrumented observations, the long
wait lies after GPU completion, not in slow CPU preparation, long GPU execution
or a long commit-to-GPU queue wait. The remaining interval includes the display/
compositor/presentation path; this does not identify a specific macOS component,
prove physical scanout latency, exonerate the reader in every case, or explain the
five earlier unprofiled gaps. Absence of nearby reads is not causal proof.

[Native gap summary](native-gaps.json), [all 905 derived frames](native-timeline.json.gz)
and [target-only native inputs](after-metal-full-window/native-input.json.gz)
allow checking the numeric result against the archived application report.
Raw system traces/TOCs and unfiltered GPU/CPU exports stay on TB5 because they can
contain unrelated processes and environment metadata; [local locations](local-traces.json)
and [export hashes](export-identities.json) identify them without publishing them.
Only the target process and its command-buffer records were extracted for this packet.

Reproduce the same join from this repository without Instruments or private exports:

```sh
rtk proxy python3 specs/performance/validation/2026-10-23-cadence-study/analyze-native-timeline.py specs/performance/validation/2026-10-23-cadence-study/after-metal-full-window
```

[Archive identities](archive-identities.json) retain compressed/uncompressed hashes;
[local validation](validation.json) records reproduction, syntax, docs and structural
checks separately from the historic runtime tests. No additional app build was
needed or performed. The installed app stayed closed and was not replaced.

## Specification impact and next bounded experiment

Affected descriptive roles remain PerformanceProbe.Measurement.FrameCPU,
GPUCompletion, Presentation and SyntheticFeed.BackgroundReads; the reader's
`no_frame_mailbox_io`, cache and lifetime claims remain on their existing source.
`dreams.performance.measure` observation/provenance/feed_comparison are the relevant
claims. No implementation binding, map, requirement, acceptance state or historic
measurement is rewritten: runtime and production tools are byte-identical.

Next: extend the opt-in report with absolute GPU start/end and actual commit time
for **both** preserved variants, retaining the same observer in each. Separate
CPU preparation, commit-to-GPU wait and GPU-end-to-presentation spans in alternating
unprofiled runs on the same fixture. Preserve runtime/binary identities, measure
the observer's added cost and retain every result. A frame in the original pinned
binary cannot retroactively acquire missing GPU timestamps.

Only after that comparison should an implementation remedy be chosen. Do not
move rendering queues, change presentation synchronization, weaken cadence
criteria or accept #42 based on these profiler-confounded observations. There is
no new physical TV, fullscreen/multi-display, memory/energy or visual acceptance.
