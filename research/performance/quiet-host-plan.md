# Quiet-host follow-up — proposed, not yet collected

The [absolute-timeline series](../../specs/performance/validation/2026-10-23-absolute-timeline/README.md)
preserves valid diagnostic inputs but has no concurrent external-load record.
The owner reported another parallel agent likely compiling Rust and Swift.
Its exact overlap and contribution cannot be recovered from a later process list.
This plan does not retroactively invalidate files, establish a cause, accept a
budget or alter the immutable timestamp protocol used for that series.

## 1. Separate the questions

- Quiet host: does the changed implementation improve its target metric while
  preserving cadence, with comparable system conditions?
- Loaded host: how does each implementation behave under the same deliberately
  specified background workload? This is a separate robustness experiment.

Do not mix ordinary interactive work, arbitrary builds and quiet-host results.
Do not infer renderer CPU cost by subtracting other processes' CPU from elapsed
frame time; retain process CPU, CPU elapsed spans, GPU duration and presentation
intervals as distinct observations.

## 2. Prepare a bounded quiet window

Build and test both identified executables before the window. Coordinate with the
owner so other agents do not build/test during measurement; this task does not
terminate or suspend unrelated processes. Keep the installed Dreams closed and
retain the same fixed fixture, trace, resources, drawable and display arrangement.
Record power connection/mode, OS, device and thermal state. Do not silently change
system indexing, display settings or process priority to obtain favorable results.

Collect a short idle reference before choosing the experiment's load thresholds.
Before any comparison, commit the duration, repeat count, order, monitor version,
sampling interval, thresholds and handling of contaminated runs. Use alternating
paired implementations with the same observer and bracketing controls as needed.
Do not start another 45-minute series until a quiet window is available.

## 3. Record enough host context to detect contamination

Use a separate bounded monitor; keep its observations outside the frame path.
Prefer aggregate CPU activity, busy build-tool presence, memory pressure/swap,
thermal/power changes and precise host-clock correlation. Avoid command arguments,
environment dumps, private paths and unrelated user content in published evidence.
If scheduling or compositor/GPU attribution is needed, collect a separate bounded
system trace and identify its additional observer cost; do not mix it into baseline.

The monitor itself needs a lightweight on/off check. Fixed low-frequency sampling
can detect sustained compilation but cannot prove absence of every short scheduling
interruption. Missing host data must remain unknown, not be interpreted as idle.

## 4. Classify before interpreting performance

Define environmental validity separately from report, delivery and clock validity.
Contamination rules must depend on host observations, never on a long-frame result.
Retain every original run and the reason for classification. If a pair is affected,
follow the precommitted replacement/stop rule for the whole comparison unit; preserve
both original and replacement rather than silently deleting an unfavorable run.

Compare per-pair changes with control variation and the measured system context.
Nominal thermal state alone is insufficient. Negative overhead estimates do not
prove a speedup, and a non-reproduced gap does not resolve the original cause.
If a clean comparison remains inconclusive, preserve that result rather than
growing the run count or changing thresholds after seeing outcomes.

## 5. Choose the next change from evidence

Only then decide whether there is a reader/cadence regression, a detectable observer
cost, or primarily sensitivity to external load. A loaded-host experiment should
use one explicit reproducible load on both variants and remain a separate dataset.
No present evidence closes issue #42 or makes PR #54 ready automatically. Physical
tvOS and multi-display acceptance require their own device/profile checks.
