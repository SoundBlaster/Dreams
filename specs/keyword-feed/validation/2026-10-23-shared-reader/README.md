# Shared reader impact — 2026-10-23

Runtime source: `680833b15edb0435c31bf3f4f1bc3c17ca934dd5`.
Affected claims: dreams.feed.read: no_frame_mailbox_io, shared_snapshot, freshness_and_expiry, errors, lifetime, assembly.

[Shared execution and integrity evidence](../../../performance/validation/2026-10-23-shared-reader/README.md)
separates source/thread observations, functional/offscreen tests, paired window
measurements and structural checks. [Pinned input](../../evidence/2026-10-23-shared-reader/source-identity.json)
refreshes this package's affected renderer/reader dependencies without promoting
historical tests or visual observations to this runtime.

This is a newly recovered descriptive draft. One default process-local reader
feeds renderers through immutable cached snapshots; each renderer owns its lease
and consumed event IDs. Tests cover notification/fallback, error/cache, expiry,
directory replacement, last-consumer cancellation and two-renderer event delivery.
Status/session-listing and producer semantics remain outside this boundary.

Five primary paired runs establish off-main mailbox reads and lower delivery
p95 in this fixture. Rare >50 ms presentation gaps occurred only after the
change and repeated in a separate quiet diagnostic; cadence acceptance remains
open. Structural success is separate from behavior and owner acceptance.
Physical overlay, multi-display, complete-text/pixel latency and tvOS performance
are not established by these tests. No numerical performance budget is accepted.
