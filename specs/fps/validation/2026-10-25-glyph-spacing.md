# TV common-body sizing adoption — 2026-10-25

`dreams.rain.fps/appearance` inherits the active TV rain atlas scale so reserved
FPS cells keep the rain's quad size and fixed grid centers. Sampling/opt-in/
lifetime remain unchanged. The shared FPSGrid scale defaults to1, preserving
macOS/default sizing; invalid scales are rejected. Current snapshots and source
hashes replace only changed files; old evidence remains historical.

[TV validation and limits](../../tvos/validation/2026-10-25-glyph-spacing/README.md)
record source b34f92a831851701b3f64d7f630c6581901a418d, actual atlas coverage,
21 TV tests, focused shared macOS checks and separate visual/device scope. No
physical cadence/overhead, film-fidelity or macOS UI acceptance is inferred.
