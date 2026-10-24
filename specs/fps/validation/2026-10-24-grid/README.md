# FPS in rain cells — 2026-10-24

Three cells at the visible top-right grid edge are reserved only after a valid
sample is available. The counter uses the same normalized glyph quads as rain,
with its own readable Dreams digits. Underlying rain cores and halos are skipped;
simulation data remains intact. No separate shadow or pixel-size override remains.
Cropped preview uses its whole visible columns while retaining the full viewport
scale; placement below playback controls is rounded to a grid row.

Metal offscreen render and geometry/sampling tests: 4 passed. TV Simulator
Release regression suite: 19 passed. Final suite, current bindings and physical
installation are recorded in results.json. UI/runtime screenshots are separate
from the deterministic pixel test and physical frame-rate acceptance.

The simulator app launched with argument-only FPS overrides; preferences were
not changed. The interaction session disappeared and screenshot fallback failed
with a permission error. No simulator alignment screenshot/acceptance is claimed;
session cleanup was confirmed. Deterministic Metal pixel verification passed.
The physical Release was built, installed preserving data and launched; owner
visual acceptance remains separate.
