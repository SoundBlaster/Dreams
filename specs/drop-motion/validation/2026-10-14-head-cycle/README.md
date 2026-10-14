# Continuous head trials — 2026-10-14

Runtime `ab6290c47f24c43a7ce7e6fdd71272ae6abb34c7`; [source and map identities](../../evidence/2026-10-14-head-cycle/source-identity.json).
The changed HeadAppearance map is separately hashed; all other role and claim identities remain stable.
Historical pulse/head/motion/search records are preserved on their original sources.

The initial implementation `93f5069` excluded the head from opportunistic trail searches and rendered
the stored glyph. Current code prior to this change only selected a fresh head glyph on each row write
or by occasional quota search. This change adds continuous presentation trials rather than claiming
to restore a deleted continuous loop. The cadence is 0.035 simulation seconds and follows rain speed.

The head uses a deterministic full-repertoire sequence independent of both stateful random generators
and the trail search fraction. It does not change the stored glyph, timestamps, ink, alpha, motion or quota.
The final row's phase stops at its flight arrival while its pale highlight fades. Keyword heads use
code trials until the head leaves, then normal word/search presentation applies. There is no new setting.

[Regression](regression.log) restores the exact prior committed MatrixRain renderer with the new model
and outline tests retained: both background cases fail only their changing-outline assertion.
[Corrected unit and GPU run](unit-metal.log) passes 52 tests in 18 suites, including zero/saturated quota,
read determinism, one-glyph/expired/finished heads, same-row outline changes, pale gap/dim heads,
transparent alpha fade, brightness pulses and settings persistence. [Focused model](model.log),
[focused pixels](gpu.log), [lint](lint.log), [run receipts](runs.json) and [structural checks](structure.log)
record distinct evidence levels. GPU fixtures use the production offscreen Metal frame with an isolated
empty feed and no glow, not a physical desktop compositor or a live-device observation.

Stable `dreams.rain.drop_motion`, `dreams.rain.search_occupancy`, `dreams.rain.glyph_pulse` and existing
head visibility constraints remain applicable. The additive head_trials draft is folded into HeadAppearance.
Overlay lifetime/display/input, native feature-flag/range/ownership and tvOS presentation are unchanged.
Shared model source compiles for macOS here; tvOS renderer does not consume headGlyph and no new TV
execution or acceptance is claimed. User glyphs, font assets and checkpoints are untouched.
