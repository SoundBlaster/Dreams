# SDK and shader topology baseline — 2026-11-16

Base `c73807d2eb97ac863738d1bba20af3db1190f90b` preserves the CPU optimization.
The shader candidate is identified by [dated source/map hashes](../../evidence/2026-11-16-sdk-gpu/source-identity.json),
not by that base SHA alone. Historical source and validation are retained.
The [investigation](../../../../research/performance/2026-11-16-sdk-gpu.md)
separates SDK/toolchain comparison, GPU topology comparison and startup-cache experiments.

## Impact and assembly obligations

Desktop MatrixRain uses four strip vertices instead of six triangle-list vertices
per instance. Shared `matrixCorner` retains the original rect/UV/color/seed math;
`matrixVertex` retains its original six-vertex interface for FPS and television.
The fragment shader, instance order, blend state, atlas, geometry, simulation,
CPU-to-Metal copy, cadence and halo floor are unchanged. No product requirement,
role/claim identity or acceptance state changes.

- `dreams.rain.drop_motion` timing, grid, tail, event and parent-assembly claims;
  `dreams.rain.search_occupancy` occupancy/motion/parent claims;
  `dreams.rain.head_visibility` and `dreams.rain.glyph_pulse` appearance/assembly
  claims retain the same inputs and fragment/instance math. Pixel equivalence is
  new evidence for the exercised frames, not a universal proof.
- `dreams.rain.frame_budget/glow_frame_rate` and `invisible_halo_floor` retain
  the existing 60 Hz no-glow / 30 Hz glow policy on this display and the literal
  1/16384 threshold. No quality/FPS tradeoff is introduced.
- `dreams.feed.read` snapshot/error/lifetime/assembly claims and
  `dreams.performance.measure` isolation/observation/provenance/calibration
  claims are unchanged. Draw calls still allocate instance buffers. Fewer vertex
  invocations are not claimed as fewer buffer copies or measured power savings.
- Overlay per-display ownership, settings-preview ownership and FPS reservation
  remain unchanged. FPS uses the retained six-vertex entry point. HC composition
  and profile meanings do not change; map hashes are recorded without cosmetic edits.
- `dreams.tv.rain` appearance, head/pulse, resources and platform-boundary
  obligations are revisited because the shader file is shared. The television
  renderer still requests the six-vertex entry point; source compatibility is
  distinct from tvOS compilation, physical-device behavior and acceptance.

This small behavior-preserving topology change does not recover the complete
shader/atlas, controller or hook subsystems as accepted contracts. Existing
unexplored boundaries remain backlog. Current affected full-file bindings are
refreshed in drop-motion, frame-budget, keyword-feed, performance and tvOS.

## Evidence and remaining checks

Raw commands, source/binary/resource identities, build/test logs, rejected runs,
per-run reports and host-load snapshots are under `artifacts/sdk-20261116/` and
`artifacts/gpu-20261116/`. The investigation records final validation outcomes.
Source/tool identities distinguish CLT Swift 6.4 + SDK 26.5 from Xcode 27.2
build 27B52 / Swift 6.4.2 + SDK 27.2; both target macOS 15.0.

The four-vertex candidate has 32 byte-identical replay PNGs on each toolchain.
Specialized fragment functions are **rejected**: two transparent replay PNGs
differ by three pixels total (maximum channel difference 2/255). They are not in
the candidate or used as evidence for its performance.

Required `legacy-to-specs`, `hypercode-architecture-map`, `specpm-legacy-boundaries`,
`specpm-author-spec`, `specpm-review-spec` and `no-wait` skills, and `rtk`,
`hypercode`, `specpm` executables remain unavailable. Their absence is explicit;
generic YAML/docs checks cannot substitute for official validation. Pending
official scopes: affected packages, application/overlay profiles, motion,
search, pulse, frame-budget, feed, performance, FPS, settings-host and television.
Structural validity, source review, app/Metal tests, windowed measurements,
physical devices and release acceptance remain separate. All contracts stay drafts.

## Final local outcomes

Final Xcode Release suite: **115 tests in 29 suites passed**, including the four
direct quad-equivalence cases and all 32 replay PNGs. The unchanged new-SDK
baseline also matches the old SDK's 32 PNGs. Opt-in interactive/device checks
remain skipped. See [commands and exit codes](checks.json), [PNG identities](replay-comparison.json),
[source/binary provenance](strip-provenance.json) and [baseline identity](baseline-provenance.json).

All 18 retained comparison runs are valid. In three alternating pairs per
profile, GPU p50 run-level medians improve 0.7820 → 0.6249 ms without glow and
4.3313 → 3.8908 ms with glow. Cadence is not improved; glow retains long intervals
on both sides. SDK/compiler comparison alone shows no robust improvement.
[Individual results](comparison-summary.json) and [local raw evidence hashes](local-evidence-manifest.json)
preserve the scope; rejected presentation and fragment-specialization attempts
remain separate. [Startup cache results](cache-summary.json) do not justify a
production disk-cache change. None of these observations establishes a power,
fullscreen, TV or release acceptance claim.
