# Publisher contention in reader fixtures — 2026-10-25

Release-preparation CI [40135742996](https://github.com/SoundBlaster/Dreams/actions/runs/40135742996)
on metadata head `62db429` passed unit checks but failed a subsequent all-tests
invocation: directory replacement triggered a background read while the fixture
publisher tried the nonblocking mailbox lock. Its documented busy/retry error
escaped the test. The failed log is preserved separately, not relabeled as a pass.

Test source `9edaa7f3706743c95b70164232a80a996d4840af` retries only that specific transient error, bounded
by five seconds. Before retrying it awaits the competing reader; all other errors
propagate. After a successful commit the existing session-content waiter still
requires notification-driven delivery within five seconds, without requesting
another read. The fixture fallback remains 30 seconds, so it cannot satisfy that
assertion. Active-reader publishes use this helper; intentional lock-failure
assertions and production reader/publisher code are unchanged.

`dreams.feed.read/shared_snapshot`, `freshness_and_expiry`, `errors` and `lifetime`
retain their requirements, roles, profiles and descriptive-draft status. Only the
current test snapshot/source identity changes; historical evidence is preserved.
No performance, renderer, tvOS or physical-device acceptance is inferred. Current
commands, tool/map identities, diagnostics and results are recorded in `checks.json`.
