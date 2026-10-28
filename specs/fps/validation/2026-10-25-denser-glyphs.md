# Denser TV rain sizing — 2026-10-25

`dreams.rain.fps/appearance` still inherits the active atlas scale. TV now uses
1.12 nominal cap bodies per row with a uniform XY factor; FPSGrid and the TV
renderer source themselves are unchanged. The refreshed renderer/atlas test
confirms matching quad sizes. Cadence, lifetime, opt-in and macOS default scale
remain unchanged. [Current TV checks and limits](../../tvos/validation/2026-10-25-denser-glyphs/README.md)
identify source8830eab2fc5361d1b154a5969d072fe15da579d2. Historical tests and
snapshots stay historical; physical cadence/GPU cost and owner acceptance are
outstanding.
