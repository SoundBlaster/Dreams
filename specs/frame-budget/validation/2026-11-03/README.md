# Frame budget and invisible halos — 2026-11-03

Runtime source `8deda1e1d38b1349cad78cca966749ce5c827a9f` on base `4569dfc`.
Host: MacBook Pro M4 Pro, built-in XDR 3024×1964, screen maximum 120 fps.
Commands, exit codes, logs and binary digests: [results.json](results.json).

## Contract and TDD

`dreams.rain.frame_budget/glow_frame_rate` and `invisible_halo_floor` are new
descriptive drafts. Red: the new tests first failed to compile without
`RainFrameBudget`. With the policy alone, halo culling failed. The view-rate
test already passed because 30 fps was the old fixed request. The TV test was
first executed after its implementation, so no TV Red was observed.

## Visual equivalence

`--render-demo` with an empty isolated feed is deterministic. The first-tried
1/512 floor changed near-black halo skirts by up to 15/255; 1/8192 still changed
2/255. With the adopted 1/16384 floor all 180 frames are byte-identical to the
previous shader. Transparent output is covered only by existing transparent fade
tests; TV pixels and the live compositor were not compared.

## Measurements (median of 3 runs, range in brackets)

| Scenario | Presented FPS | GPU p95 ms | CPU draw p95 ms |
| --- | --- | --- | --- |
| normal 1920×1080 | 30.0 → 30.0 | 7.13 (6.20–7.39) → 3.71 (3.71–4.83) | 4.50 → 3.62 |
| dense 1920×1080 | 30.0 → 30.0 | 5.93 → 4.92 | 5.91 → 5.83 |
| dense-no-glow 1920×1080 | 30.0 → 120.0 | 0.97 → 1.63 | 5.47 → 4.84 (4.80–9.30) |
| normal 3024×1964 | 30.0 → 30.0 | 7.50 → 7.46 | 3.12 → 3.18 |
| dense 3024×1964 | 30.0 → 30.0 | 12.46 → 12.07 | 6.73 → 6.65 |
| dense-no-glow 3024×1964 | 30.0 → 120.0 | 2.03 → 2.67 | 6.36 → 9.79 (5.60–9.92) |

All 36 runs are valid. Halo instance counts are unchanged in every scenario, so
the CPU floor does not trigger here. GPU gains come from fragments whose sampled
coverage is zero. The baseline `normal` 1080p runs spread widely (6.20–7.39), so
that gain needs repetition before it is trusted.
At 120 fps without glow GPU time per frame rises, likely from different clock
states. CPU draw p95 includes drawable waiting and approaches the 8.3 ms
interval on Retina. These are windowed probe observations, not fullscreen,
power, thermal or Apple TV results.
