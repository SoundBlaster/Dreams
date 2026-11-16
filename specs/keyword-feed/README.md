# Shared mailbox reader — descriptive draft

Latest MatrixRain storage bindings: [2026-11-16 retained-capacity review](validation/2026-11-16-storage/README.md).

Previous shader bindings: [2026-11-16 SDK/shader baseline](validation/2026-11-16-sdk-gpu/README.md).
Prior dated source validation remains historical; descriptive-draft acceptance is unchanged.

Previous CPU-only `MatrixRain` baseline (before the shader change):
[2026-11-16 CPU/GPU baseline](validation/2026-11-16-cpu-gpu/README.md).
Earlier dated results below remain historical for changed renderer source;
requirements and descriptive-draft acceptance are unchanged. Official HC/SpecPM
validation of this candidate is pending because those tools are unavailable.

The [contract](specs/reader.spec.yaml) covers macOS rain consumers of ready mailbox
snapshots. [Map](../hypercode/keyword-feed.hc) and
[properties](../hypercode/keyword-feed.hcs) separate the cache, subscription
lifetime, background observation and offline fresh-input request.

[Dated validation](validation/2026-10-23-shared-reader/README.md) records source,
functional/offscreen checks and the controlled before/after comparison separately.
This draft does not recover producer hook/MCP semantics, promise hard real-time
delivery, remove on-demand status I/O or establish physical Apple TV acceptance.
