# pr53 main integration

Source baseline `14b9f3b35caca1d48b1a8c4428cdbac4693a6846`. Main and the PR are combined without reclassifying historical tests or performance observations as current acceptance.

[Source and map identities](source-identity.json) pin dependency snapshots refreshed during integration, including pre-existing drift. Stable role/claim identities and requirements remain unchanged unless an explicitly described fix accompanies this packet. Structural, application, CI and physical-device evidence remain separate. Local validation commands/results are recorded in the following integration checkpoint; CI is evaluated for the final pushed head before merge.

## Local checks

[Commands, tools and results](checks.json): HC/SpecPM structure, relative documentation links and whitespace checks pass (exit 0). Existing unresolved external/platform capability warnings remain. Source/map identity is recorded separately from these structural checks; application/physical-device and performance acceptance are not claimed.

## PR #53 delivery review correction

`dreams.performance.measure/feed_observation` now explicitly rejects a feed fixture whose reference width or height exceeds the drawable, before constructing the measurement window. This prevents the normalized full-viewport letter test from claiming delivery for clipped-away letters. Normal performance probes still accept preview-crop. No production viewport/rendering formula changes.

Eight Release Swift tests pass, including the real preview-crop fixture and width-only/height-only rejection. The actual Release executable rejects cropped feed input with exit 1 and creates no report; SwiftLint passes with the existing analyzer-rule configuration warning. The prior five full-viewport baseline runs retain their original source identity and are not rerun or relabeled as evidence for this correction. The initial executable-path lookup used an obsolete SwiftPM layout; `--show-bin-path` located the actual TB5 `out/Products/Release` product before the CLI check.
