# Glyph pulse integration — 2026-10-14

Runtime `74b57fa2a4ea8e6934024dd57706c39d42e331c0`; [current identity](../../evidence/2026-10-14-pulse/source-identity.json).
The added pulse scalar uses the existing controller preference/renderer/notification path.
Stable claim IDs and draft acceptance remain: overlay lifecycle/input ownership and native
routing, shared ownership, ranges and cleanup retain their meanings. Changed implementation
bindings and map hashes are repinned; old baselines and acceptance limits are preserved.

[Current rain tests and checks](../../../drop-motion/validation/2026-10-14-pulse/README.md)
contain 47 Swift/GPU passes and fresh structural checks. Pulse propagation adds no windows
or display policy, does not enable native settings, and does not modify timer/hotkey ownership.
Physical desktop compositor and keyboard/device acceptance remain separate and unobserved.
