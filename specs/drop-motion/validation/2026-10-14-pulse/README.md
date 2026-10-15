# Glyph pulse baseline — 2026-10-14

Runtime `74b57fa2a4ea8e6934024dd57706c39d42e331c0`; [current identities](../../evidence/2026-10-14-pulse/source-identity.json).
The newly recovered `dreams.rain.glyph_pulse` draft covers real-time whole-glyph exposure and
shared strength controls. Stable motion/search/head claim IDs remain, with changed integration
sources repinned. Older execution results remain historical, not results for this revision.

[47 Swift tests with Metal enabled](unit-metal.log) pass, including smooth bounded phases,
zero/invalid inputs, shared native/legacy persistence and read-only MCP reporting. On/off
GPU comparisons for both backgrounds show changed whole-glyph brightness with unchanged
alpha coverage; existing pale-head and alpha-expiry regressions pass. The alpha-only fixture
sets pulse to zero to isolate its own contract. Native visual/compositor and physical-device
acceptance are distinct and unobserved here; tvOS implementation is unchanged.

[Phase-helper sample](performance.log) measures only the pure gain calculation at 240×135,
60 frames, not whole-frame FPS. [Structure/docs/lint](checks.log), [tools](tools.json) and
[run record](runs.json) are separate evidence. Platform/capability resolution warnings remain
explicit. Glyph fonts, user checkpoints and launch feature flags are unchanged.

The hosted-runner workflow remains unchanged: its GPU step is best effort and currently selects only alpha-fade checks. Head and pulse pixel tests were executed locally with the broader selection in [ci-metal-selection.log](ci-metal-selection.log). The optional workflow extension was omitted because the current GitHub OAuth credential lacks workflow scope. [Workflow identity](verification-inputs.json) records the unchanged input. CI green alone does not prove pulse GPU execution.
