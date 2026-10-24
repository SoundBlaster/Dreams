# Quiet-host prerequisites — 2026-10-24 (Moscow)

The owner offered a quiet window. Both preserved binary hashes match the earlier
timestamp experiment and the host is on AC power. **No renderer comparison was
started:** two retained one-minute idle references exceed the prospectively chosen
quiet prerequisite. No threshold was changed after seeing results, no process was
stopped, and no build, app installation or preferences migration was performed.

This is an environmental prerequisite result, not evidence of an application
regression or proof that background load caused the historical presentation gaps.
The threshold is a conservative operational guard for this attempted pilot, not
an accepted performance budget or a general definition of an overloaded Mac.
PR #54 and #55 remain draft; issue #42 remains open.

## Planned scope and preservation

The intended pilot was two pairs with reverse implementation order: before → after,
after → before, each using the existing 30 s warmup / 60 s collection fixture and
timeline enabled on both variants. Four runs would remain a pilot, not the required
five-pair comparison or a new observer-overhead calibration.

Before starting any renderer, [preflight plan](runs/preflight-plan.json) fixed
10 s control → 20 s monitor → 10 s control, followed by a 60 s idle reference.
The prerequisite thresholds were p95 host busy ≤1.5 cores and maximum ≤3 cores,
no observed active build tools or Dreams, normal memory pressure, no increase in
swap-out pages and AC power. The p95 guard was selected prospectively as a
conservative gate; it was not derived from an accepted device budget.

After the first failure, a separate 10 s process diagnostic identified currently
active consumers. A [second-reference plan](runs/reference2-plan.json) explicitly
allowed one final prerequisite attempt with the same thresholds after completing
interactive tool/UI activity. Both references remain preserved; the second did not
replace the first or any benchmark. No further retry or threshold relaxation followed.

## Observations

| Reference | Median busy cores | p95 busy cores | Maximum busy cores | p95 ≤1.5 | Other recorded prerequisites |
| --- | --- | --- | --- | --- | --- |
| First 60 s | 1.183 | 2.050 | 2.935 | Failed | Passed |
| Second 60 s | 1.262 | 2.251 | 2.649 | Failed | Passed |

Values are total aggregate busy CPU expressed in equivalent cores out of 12, not
percent of the entire machine. The two p95 values correspond to approximately
17.1% and 18.8% of total CPU capacity. At this stage Dreams was absent, so no
renderer subtraction is involved. These percentiles are separate, not pooled.
The median load is modest; failure of the selected gate does not establish that
this background activity would distort a particular application measurement.

No active compiler was detected by the exact-name, ≥0.1-core interval test.
Both references recorded normal memory-pressure level `1`, AC power and unchanged
swap-out counter (5,744,150 pages). Existing swap usage was about 7,013 MiB; this is
historical allocation, not evidence of current swap-out activity. Process sampling
cannot establish that no short-lived compiler existed between snapshots.

The separate [10 s diagnostic](runs/after-reference-processes.json) observed
Codex Service ≈18.8%, Codex Renderer ≈14.4%, WindowServer ≈16.0%, a virtualization
process ≈8.9% and Screener MCP processes ≈7.9% of **one core**. This post-reference
sample cannot assign the preceding minute's peaks or the earlier cadence gaps.
No arguments, environment dumps or full process paths were published.

## Observer cost and limits

The external observer samples at 1 Hz. CPU ticks use native `host_statistics`,
`HOST_CPU_LOAD_INFO=3`, four states verified against installed SDK headers. Process
CPU deltas use `ps` cumulative time; memory/swap and AC state are sampled every
five iterations. All records use `CLOCK_UPTIME_RAW`, the same host domain as the
existing synthetic feed clock. Results stay in memory until the observer exits.

| Mode | Sidecar + sampled child CPU seconds / elapsed second |
| --- | --- |
| Control 1, 10 s | 0.00007537 |
| Full monitor, 20 s | 0.05539248 |
| Control 2, 10 s | 0.00009566 |

Signed full-minus-control-mean is **0.05530697 CPU s/s**, roughly 5.53% of one core
or 0.46% of aggregate 12-core capacity. This single short C/F/C block estimates
process CPU for the sidecar and its sampled commands only. It does not calibrate
renderer latency, compositor interference, total system overhead, a confidence
interval or a zero-overhead claim. Earlier timestamp-observer cost remains unresolved.

Sampling can miss short-lived process identity. Aggregate host ticks still include
such CPU activity, but do not locate scheduler/GPU effects. The helper's signed
external estimate is unused here because Dreams never ran. No frequency, energy,
GPU scheduling, physical scanout or tvOS observation follows. This sidecar did not sample thermal state. Normal memory pressure and earlier
nominal thermal observations do not prove absence of all competition.

## Evidence and specification impact

[Identity](identity.json) pins runner, binary prechecks, Python/OS and SDK-header
hashes. [Archive integrity](archive-integrity.json) pins every raw/stored file.
[Collector input](inputs/host-monitor.py) preserves the exact experiment-only helper;
`*.json.gz` is a lossless archive. Time parsing was checked with seconds, minutes
and day/hour examples; live native tick, memory and process reads succeeded.
There was no build, package resolution or dependency installation. External
observation output and Python bytecode remained under the verified TB5 root.

Affected existing roles are PerformanceProbe.Calibration and ReportExport;
`dreams.performance.measure` provenance/calibration/observation/feed_comparison/
timeline_calibration requirements continue to apply. This dated prerequisite packet
does not change the production runtime, supported diagnostic CLI, current source
bindings, maps or contract requirements. The ad hoc collector is retained as an
experimental input, not claimed as a recovered supported host-monitor boundary.
Making environmental validity a reusable runner gate remains explicit tooling
backlog. Earlier records retain their original sources and acceptance limits.

Final docs/HC/SpecPM/archive checks are recorded in `checks.json`. Structural validity
does not promote this prerequisite to performance acceptance. The next decision is
how to define comparable ordinary idle conditions and observe their short peaks,
before preregistering a new application comparison. Preserve both failed references
when refining the future protocol; do not silently label this attempt a quiet pass.
