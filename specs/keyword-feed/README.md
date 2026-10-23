# Shared mailbox reader — descriptive draft

The [contract](specs/reader.spec.yaml) covers macOS rain consumers of ready mailbox
snapshots. [Map](../hypercode/keyword-feed.hc) and
[properties](../hypercode/keyword-feed.hcs) separate the cache, subscription
lifetime, background observation and offline fresh-input request.

[Dated validation](validation/2026-10-23-shared-reader/README.md) records source,
functional/offscreen checks and the controlled before/after comparison separately.
This draft does not recover producer hook/MCP semantics, promise hard real-time
delivery, remove on-demand status I/O or establish physical Apple TV acceptance.
