# Feed baseline protocol — 2026-10-23

Related: [#42](https://github.com/SoundBlaster/Dreams/issues/42),
[measurement plan](../performance-measurement-plan.md).
This is a baseline stage, before changing feed ownership or scheduling.

Use the Release production renderer, dense scenario (1920×1080, 160 columns,
100% density, 10% searching, glow on), 30 s warmup and 60 s collection, five
serial repetitions. Preserve all runs and do not select only smooth ones.
One window, one renderer, default simulation seed, real elapsed clock and
forced steady activity. Installed Dreams rain must be stopped; no screenshots,
profilers, builds or tests during collection. Keep binary/resources/fixtures
identical. Record thermal state and host/display identity. These are interactive
desktop observations with uncontrolled background activity, not laboratory gates.

An external Python process creates an empty disposable mailbox, waits for the
app's startup clock handshake and atomically writes 24 synthetic working
sessions during warmup. It then publishes the fixed
[trace](feed-trace.json), including first/repeated Latin/Cyrillic/command labels,
at varying phases of the one-second poll. Each event has a deterministic UUID
and its own session. Twelve already-expired files arrive during collection;
the final mailbox must contain only the 24 active sessions. No private live
mailbox, preferences, hook installation or MCP traffic is involved.

Record both sides of each atomic rename and the actual schedule lateness.
Python's [monotonic clock](https://docs.python.org/3/library/time.html#time.monotonic)
uses `mach_absolute_time` on macOS and shares its domain across processes.
Require the startup handshake to agree with the runner clock within five seconds.
Use the same host clock as the renderer's `CACurrentMediaTime` and drawable
[`presentedTime`](https://developer.apple.com/documentation/metal/mtldrawable/presentedtime).
Publication denotes filesystem namespace visibility, not durable storage flush.

Opt-in feed observations record each snapshot API attempt's start/end, success,
main-thread flag, returned session count and event IDs. They do not count syscalls,
separate lock/read/decode/prune costs or establish cold-disk latency. Other frames
have no refresh observation; don't dilute the refresh percentile over all frames.
Record refresh/other draw spans, presentation cadence, glyph rasterizations and
per-event receipt latency. New-letter rasterization (#46) can contribute to draw
cost and is not attributed to feed reads.

Delivery proxy: the earliest actually presented drawable containing a submitted,
stable, non-space glyph instance belonging to the event, with positive alpha and
color inside the full viewport. Exclude searching/head substitutes. Report the
latency bracket from atomic rename start/end. This is **not pixel/OCR evidence**,
full-label readability, physical display scanout or unobscured-window acceptance.
Validate every expected event; absent observations remain missing and invalidate
delivery, never become zero latency. Keep frame validity and delivery validity
separate. A smoke run (1+12 s, two events) only checks the machinery.

Before/after acceptance for #42 still requires removing filesystem I/O from the
frame path and repeating this fixture without worse delivery/cadence. This baseline
does not prove the issue's proposed high impact, shared multi-display behavior,
lock-contention behavior or an optimization gain. The collector's additional feed
observation cost is uncalibrated; PR #52 did not calibrate this new instrumentation.

Commands:

```sh
python3 scripts/run-feed-performance.py --output <new-external-directory>
python3 scripts/analyze-feed-performance.py <directory>
```
