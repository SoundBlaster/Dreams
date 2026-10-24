# pr40 main integration

Source baseline `5f1c3fd54c06d949e8d70c13cfefefc5dcb1a065`. Main and the PR are combined without reclassifying historical tests or performance observations as current acceptance.

[Source and map identities](source-identity.json) pin dependency snapshots refreshed during integration, including pre-existing drift. Stable role/claim identities and requirements remain unchanged unless an explicitly described fix accompanies this packet. Structural, application, CI and physical-device evidence remain separate. Local validation commands/results are recorded in the following integration checkpoint; CI is evaluated for the final pushed head before merge.

## Local checks

[Commands, tools and results](checks.json): HC/SpecPM structure, relative documentation links and whitespace checks pass (exit 0). Existing unresolved external/platform capability warnings remain. Source/map identity is recorded separately from these structural checks; application/physical-device and performance acceptance are not claimed.
