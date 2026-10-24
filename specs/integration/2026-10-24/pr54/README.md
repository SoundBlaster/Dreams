# pr54 main integration

Source baseline `c6da1a590ca7658dd885fa33096564d5830a4f81`. Main and the PR are combined without reclassifying historical tests or performance observations as current acceptance.

[Source and map identities](source-identity.json) pin dependency snapshots refreshed during integration, including pre-existing drift. Stable role/claim identities and requirements remain unchanged unless an explicitly described fix accompanies this packet. Structural, application, CI and physical-device evidence remain separate. Local validation commands/results are recorded in the following integration checkpoint; CI is evaluated for the final pushed head before merge.

## Local checks

[Commands, tools and results](checks.json): HC/SpecPM structure, relative documentation links and whitespace checks pass (exit 0). Existing unresolved external/platform capability warnings remain. Source/map identity is recorded separately from these structural checks; application/physical-device and performance acceptance are not claimed.

## Expiry test and integration disposition

The two historical CI failures share the same setup race: a 0.5-second real-wall-clock TTL can expire before the first asynchronous read under load. The test now controls a mutex-protected wall clock; it advances only after the initial snapshot and then awaits fallback pruning without another publisher write or explicit refresh. The reader uses its injected clock consistently for snapshot expiry, recent events and pressure. Production defaults remain Date(), and the monotonic performance clock is unchanged. Reader caching, error retention, observation, lifetime and parent bindings retain their requirements.

Release checks report 13 tests in two suites, with the opt-in Metal case skipped; SwiftLint and HC/SpecPM/docs pass. The owner requested source delivery to main on 24 Oct. This supersedes the earlier draft delivery disposition, not the unresolved cadence/performance acceptance. All historical paired runs, failed host-load prerequisites and unprofiled gaps remain retained; issue #42 stays open. No new performance benchmark, TV optimization or physical-device acceptance is claimed.
