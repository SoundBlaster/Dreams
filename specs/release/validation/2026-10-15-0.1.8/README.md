# Dreams 0.1.8 release preparation — 2026-10-15

Metadata source `732a9bde704d48c620dcc1c650cb2e87d18cd671` changes VERSION and both plugin version fields to 0.1.8.
[Identity](source-identity.json) pins their hashes and the current rain/overlay/settings contract identities.
Every source/map hash in those identities was compared to the release checkout; they remain unchanged.
Runtime baselines, stable claim IDs, draft acceptance and native settings opt-in retain their meanings.

[Commands, cwd, source revision and exit codes](runs.json), [tool identities](tools.json),
[plugin checks](plugins.log), [documentation links](docs.log) and [SpecPM/HC diagnostics](structure.log)
are preserved separately from old runtime tests and hosted CI. The baseline adds documentation only;
it does not change the metadata or implementation bytes identified by this revision. Older baselines
remain historical. The owner's local macOS visual observation is reported in the progress record,
not relabeled as a new automated test or formal cross-platform acceptance.

Signing, Apple notarization, stapling, Gatekeeper and final downloaded release-asset comparison
are separate publication checks; this preparation baseline alone does not assert their completion.
