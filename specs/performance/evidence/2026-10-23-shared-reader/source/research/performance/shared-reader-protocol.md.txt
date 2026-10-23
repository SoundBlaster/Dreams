# Shared reader comparison — 2026-10-23

Compare the preserved [feed baseline](../../specs/performance/validation/2026-10-23-feed/README.md)
app at `29e07ea` against the shared-reader implementation. Preserve that app bundle
and its recorded binary/resource hashes before rebuilding. Do not relabel the
preserved executable with the new source revision: the runner's `--revision`
specifies runtime identity separately from runner identity.

Use the identical dense scenario and feed trace from the [feed protocol](feed-protocol.md):
30 s warmup, 60 s collection, 24 sessions, 12 events, 12 expired files, one 1920×1080
windowed renderer, 160 columns, density 100%, searching 10%, same seed, elapsed
clock and steady activity. Five serial pairs, alternating before/after and
after/before between pairs. Preserve all ten runs; no selection by result.
Installed rain remains closed. No builds, tests, captures or profilers during
collection; disclose light documentation work and uncontrolled host/cache load.

Both implementations report snapshot API spans and event-to-presented-letter
proxy. The new reader additionally retains every observed background read during
collection, separately from frames consuming cached snapshots: notifications can
outpace a frame. `feedRefresh` on a new frame identifies consumed input, not I/O
performed by that frame. The proxy is still not pixels or complete label visibility.
No total CPU, allocation, energy, physical TV or multi-display performance claim.

Compare only matching fixtures, trace, resources, hardware, OS, display, tuning
and nominal thermal states. Different executable/source identities are expected;
each variant must keep its own identity stable across all pairs.

Acceptance evidence for #42:

1. Source review finds no mailbox `snapshot`, lock, directory, file read or prune
   call in `MatrixRain.draw`/`RainRenderer.draw`. Read observations all report
   background threads. This is an application-level invariant, not syscall tracing.
2. All 12 expected events arrive in each run and expiry still prunes the fixture.
   Each pair's p95 delivery proxy must not worsen; all-pair separation is stronger
   evidence than comparing pooled events. No tiny-gain/zero-overhead inference.
3. Retain presentation p99, >50/100 ms counts and draw spans; report any cadence
   regression instead of hiding it behind average FPS. Interpret interactive-host
   variance explicitly. Functional checks cover cache-on-error, directory
   replacement, last-consumer stop and delivery to two renderers.

The production shared reader uses directory notifications coalesced over 20 ms
and a one-second fallback. Each renderer keeps its own consumed-event set so a
shared reader cannot suppress an event on another display. Recent-event filtering
and pressure are prepared once per snapshot. Offline image generation can await
fresh input; synchronous frames only consume MainActor-owned memory.

Other on-demand `KeywordFeed.snapshot()` users (status and legacy session listing)
are outside the frame path and this change; hook/MCP producer semantics remain
unchanged. This does not claim all filesystem work in the entire app is absent.
