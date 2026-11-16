# CPU/GPU local candidate baseline — 2026-11-16

Base `48027fb5e79efdb96a3b3bf62cd70e88f2663bc3`, branch
`perf/cpu-gpu-optimization`. The candidate is an **uncommitted overlay**, identified
by [source/map SHA-256](../../evidence/2026-11-16-cpu-gpu/source-identity.json).
Implementation binding `revision` records the checkout base; dated snapshots,
not that base commit alone, identify changed files. Historical snapshots and test
records are preserved and do not establish validation of this candidate.

[Investigation and reproducible method](../../../../research/performance/2026-11-16-cpu-gpu.md)
describe the separate before/after builds and local raw evidence under
`artifacts/perf-20261116/`. No accepted product requirement is changed.

## Specification impact

Behavior-preserving implementation: precomputed code-glyph UV lookup and reused
CPU instance-array capacity in **macOS MatrixRain**. Word glyph caching and its
fallback, atlas insertion order, simulation, GPU copies, shader, rendering order,
dimensions and frame policy remain the same. The SDK selector changes only the
local build tool invocation, defaulting to the previous `macosx` SDK.

| Stable capability / affected claim IDs | Why the contract remains applicable |
| --- | --- |
| `dreams.rain.head_visibility`: `flight_visibility`, `independent_ink`, `head_trials`, `tail_and_search` | The simulation returns the same glyph index; the UV table stores precisely the constructor's original lookup result. Head/trail opacity, trial cadence and gaps do not change. |
| `dreams.rain.search_occupancy`: `simultaneous_share`, `tuning`, `burst`, `ink_lifetime`, `independent_motion`, `parent_assembly` | Search scheduling is untouched. Mutating keyword cells use the same code atlas entries; settled characters retain word glyphs. |
| `dreams.rain.drop_motion`: `deterministic_timing`, `grid_rebuild_clock`, `tail_lifecycle`, `stable_packet`, `bounded_event`, `parent_assembly` | No timing, RNG, event routing, tuning or simulation state changes. The new arrays hold render instances, not simulation cells. |
| `dreams.rain.glyph_pulse`: `independent_phase`, `bounds_and_off`, `lifetime_and_head`, `assembly` | Identical exposure/alpha math and frame times. |
| `dreams.rain.frame_budget`: `glow_frame_rate`, `invisible_halo_floor` | Identical halo culling and cadence. CPU arrays are cleared each draw; old instances cannot be submitted as a new frame. |
| `dreams.feed.read`: `no_frame_mailbox_io`, `shared_snapshot`, `freshness_and_expiry`, `errors`, `lifetime`, `assembly` | No feed reader/publisher changes; event-letter observation still requires a stable non-space keyword cell. Status uses a separate synchronous consumer, whose existing contention remains a disclosed follow-up. |
| `dreams.performance.measure`: `isolation`, `observation`, `lifetime`, `provenance`, `calibration`, `feed_observation` | Collector and counters unchanged. Buffer creations still mean successful Metal allocations; retained CPU array capacity is not falsely reported as GPU buffer reuse. New binary and resource identities are retained per variant. |

Dependent parent assemblies revisited: `RainOverlaySession.Renderer` keeps
per-display ownership and reader leases; SettingsHost preview keeps its own
renderer/clock and the same frame geometry; FPS reservation and overlay order
are unchanged. HC composition/profile semantics therefore need no cosmetic edit.
Map hashes are pinned separately. This does not recover the complete atlas/shader,
external idle-controller or production-hook integration as accepted contracts.
tvOS uses a separate renderer and is **not changed or validated** by this work.

Affected current implementation bindings are refreshed in drop-motion,
keyword-feed, frame-budget and performance packages. Historical runtime results
for those old MatrixRain hashes are not current-candidate evidence. Relevant
source-level checks and new pixel/runtime observations below replace only their
stated scope; broader compositor/device/lifecycle obligations remain unverified.

## Checks and tool limitations

Host: Mac mini M2 Pro, macOS 27.2.1 (26B131), Swift 6.4. Commands and full output
are retained in `artifacts/perf-20261116/`.

- `DREAMS_MACOS_SDK=macosx26.5 make app`: exit 0 for both variants, arm64 Release,
  ad-hoc signature. `vtool` reports minimum macOS 15.0 and SDK 26.5.
- Initial SDK 27 build: exit 1, missing CLT `SwiftUIMacros`; retained as a failed
  attempt. SDK 26.5 is selected explicitly for both sides.
- `swift-macos.sh test -c release` with explicit installed TestingMacros plugin
  path, test feed and replay directories: exit 0, **114 tests in 28 suites**.
  Initial default plugin search failed; that log is preserved separately.
- New replay exported 32 baseline PNGs, then compared all candidate PNGs byte
  for byte: all equal. These are deterministic offscreen observations, not
  physical-screen, film-fidelity or every-possible-input proof.
- `DREAMS_TEST_METAL=1` and the same Release test invocation filtered to
  DropHeadRendering/GlyphPulseRendering/RainTrailRendering/TransparentFadeRendering/
  KeywordFeedReader: exit 0, **11 tests in 5 suites**, including parameterized
  backgrounds, alpha/coverage, head trials, and two-renderer event delivery.
- Standalone `test-activity.swift` and `test-matrix.swift`: exit 0 with a
  checkout-local `-module-cache-path`. Python report/calibration/feed/cadence
  checks pass. These are separate from measured performance.
- `make specs-check`: exit 2 from make (child exit 127), missing `hypercode` at
  the first parse. Explicit `specpm validate specs/performance --json` exits 127;
  `specpm` is also absent. Required installed skills
  `legacy-to-specs`, `hypercode-architecture-map`, `specpm-legacy-boundaries`,
  `specpm-author-spec`, `specpm-review-spec` and `no-wait` were not found in the
  local skill roots or BB skill catalogue. `rtk` is absent too. Artifacts are
  preserved; ordinary shell commands were used.

Generic Ruby 2.6.10 / Psych 3.1.0 parsing of the 11 affected-package YAML files
passes (syntax only); Markdown links and `git diff --check` pass. No HC grammar
result follows from YAML parsing.

Official Hypercode parse/profile validation and SpecPM validation are **not
passed or substituted** by a generic YAML/docs check. Pending scopes: affected
packages above and HC application, overlay (opaque/transparent × interactive/
agent), motion (default/decelerating), search (default/disabled/saturated), pulse
(default/off/transparent), frame-budget (macOS and tvOS structural contexts),
keyword-feed, performance (default/control/full/feed), settings-host and FPS.
No structural, application-test or pixel result is formal acceptance. All
contracts remain descriptive drafts with their previous acceptance state.

Five complete alternating pairs passed the probe validity checks. Run-level
medians: CPU 32.72% to 29.07% of one core (−11.2% relative), instance p50
4.509 to 3.521 ms (−21.9%); GPU p50 about 0.784 ms and presentation p99
16.681 ms are unchanged. The host had unrelated load spikes; no energy or
fullscreen savings are inferred. See [individual results](summary.json),
[binary provenance](binary-provenance.json), [PNG identity checks](replay-comparison.json)
and [local raw evidence hashes](local-evidence-manifest.json).
The measurement driver exited 0, restored the installed idle-controlled app,
and controller/LaunchAgent/preferences hashes stayed unchanged. Energy, power, physical tvOS, complete
fullscreen/display lifecycle and live-agent delivery acceptance remain unknown.
