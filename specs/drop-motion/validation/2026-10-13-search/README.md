# Search occupancy validation — 2026-10-13

Source/test revision: `3a4ad943d727fb657ac9e3ada28b6e586c0b26e1`. [Identities](../../evidence/2026-10-13-search/source-identity.json)
pin implementation, exact excerpts and current maps. Earlier records remain historical.

- [Unit target](unit.log): standalone activity/matrix/hotkey checks and 29 Swift tests passed;
  GUI/GPU suites are opt-in. Search cases cover 0, 1, 10, 50 and 100 percent with one/nine columns,
  quota reduction, no resurrection, motion/ink lifetime invariance and frame subdivision.
- [Native controls](native-ui.log): completed AppKit target/action test passed, including
  default 10%, range, 0/37/100%, saved/reloaded preferences and braking controls.
- [Screener SDK capture](settings-capture.log): completed test passed. [Settings PNG](settings.png)
  inspected through MCP sessions → timeline → frame; session 7BF5F6D3-6F14-4D2E-93E5-6F0CF72A3613,
  record BDBD6D64-B2FE-45C3-B8CF-1DA4A3559DFB. New slider/percentage readable without clipping.
  Appearance evidence is this Mac's settings content, not an overlay/display-topology test.
- [Release build](app.log) passed with a temporary worktree-only glyph venv link, removed afterward.
- [CPU sample](performance.log), [witness](performance-witness.swift): swiftc -O, 240×135 grid,
  full density, 301 frames spanning five simulation seconds; ~0.25s at 10%, ~2.35s at 100%.
  These are one local model-only samples including initial fill, not FPS/rendering guarantees.
- [Lint](lint.log) passed; existing unused_import analyzer-rule warning retained.

[Structural checks](structure.log), [run metadata](runs.json) and [tool identities](tools.json)
record the remaining verification. Contracts are descriptive drafts; no formal acceptance,
tvOS adoption, physical-display topology test or release publication is inferred.
The earlier whole-state legacy PRNG witness is historical: this user-requested mutation policy
replaces opportunistic selection. Current motion tests compare disabled/zero braking at the
same search policy and separately compare 0% versus 100% search timing/ink/lifetimes.

Structural checks exit 0: HC syntax/cascade/profiles pass. SpecPM reports zero errors;
the rain package retains four unresolved platform capability warnings (WindowServer and
Metal for each of two specs); editor/overlay packages retain their prior warnings.
These external capability declarations are intentionally kept. No HC domain rules
are defined, so structural success does not prove animation semantics.
