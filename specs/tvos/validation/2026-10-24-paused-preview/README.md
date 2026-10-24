# Paused preview and A8 default — 2026-10-24

The active settings scene can request a single frame after a tuning edit while
continuous preview is off. UIKit coalesces rapid edits. Simulation/wall appearance
phase stays frozen for appearance edits, including pulse and floating-clock
phase. Speed/braking/fade/search affect subsequent simulation rather than moving
the current frame. Grid/font edits necessarily rebuild; a stable per-renderer
seed and bounded 2...8-second sample keep that still populated. Resume skips
paused wall time. Inactive scenes reject drawing. Paused stills omit FPS.

AppleTV5,3 defaults/reset now choose Glow 0; existing stored values win and
manual enabling remains available. Other hardware defaults are unchanged.

## Owner observations, preceding build cdbdbba

Physical AppleTV5,3/A8, Release, the app's GPU-completion FPS readout:
163 columns, density 88%, speed 0.51, fade 1, search 3%, acceleration -12.0.
Owner reports 11–12 FPS with menu open or closed; Glow 0% yields 25 FPS.
Clock on/off has no noticeable FPS effect. Original Glow level, test duration,
thermal state and repeated-run statistics were not recorded. This is user
observation, not an automated benchmark, a presentation FPS trace or a claim
that GPU time rather than CPU halo construction is the limiting factor.

## Validation

Final commands, source/map identities and outcomes are recorded in results.json.
Simulator UI evidence and physical installation are reported separately.

Physical Release source `734bb95` built with testability disabled, installed over
existing AppleTV5,3 data and launched successfully. Performance after this change
and the owner's acceptance remain unmeasured. Test-only simulation build enabled
testability: 19 tests passed. Initial lint found the optional String conversion rule; the follow-up initializer
correction passed `make lint`. HC/SpecPM and docs checks passed;
229 current source bindings match their snapshots. Commands, hashes and identities
are in [results](results.json).

Bounded simulator interaction attempt: installation and a live rain frame were
observed, but Select did not open settings in the captured state. No paused-edit
UI acceptance is claimed. The session ended; no test preferences were changed.
