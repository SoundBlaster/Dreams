# Bounded grid rebuild clock — 2026-10-25

Runtime source `c0dc67585501baf4d99236bc95223f3bf197e962`; final tests `af94ff0eefd217468506b64072c8293c36a87e48`. The user reported an approximately 30-second
freeze when enabling Rain > Grid Automatic in Dreams 0.1.11. A recovered-process
sample identifies a roughly nine-hour session, but was taken after recovery:
it does not identify the original hang stack. That process subsequently exited
before a sampled UI reproduction. No current Screener recording of the incident
was available; historical settings traces are not incident evidence.

Source review finds that a new MatrixSimulation began at zero while MatrixRain
advanced it to its existing session clock. The timestamp scheduler therefore
replayed all past writes/searches on MainActor after grid dimension changes.
The isolated optimized reproducer uses 110 columns, 72 rows, density 1, fade 3,
search 0.2, deceleration -37.5 and target 13,932 seconds (nine hours at speed 0.43).
The original source did not finish within a 45-second process timeout. This
controlled reproducer establishes the replay path, not the precise duration or
exclusive cause of the user's original click.

The shared simulation now accepts an initial clock origin (default zero).
Mac grid replacement starts at max(0, renderer simulation clock minus six seconds),
then advances only that recent interval. The existing renderer clock remains
continuous for activity, pulses and keyword selection. The bounded sample keeps
new/paused grids populated. This changes grid creation, not ordinary packet
kinematics, mutation policy, speed scaling, font assets or controller preferences.
TV retains its zero default and separate zero/bounded paused-clock reset.

An opt-in real-Metal regression switches 24 columns to Automatic while jumping
the posed clock to nine hours; it passes a generous one-second guard on the
isolated CPU simulation stage. This guard is not a full UI/GPU budget.
New CPU tests compare full cell/head/search/opacity behavior at zero, nine-hour
and week-shifted origins, and normalize invalid starts. The optimized after
reproducer completed its advance in 12–22 ms over three same-source runs.
Process launch overhead is recorded separately (including a slower first launch).
These are current-host diagnostic observations, not a general performance budget,
UI click latency, device FPS result or resolution of earlier collector studies.

`dreams.rain.drop_motion/grid_rebuild_clock` records the minor lifecycle rule;
`deterministic_timing` includes shifted origins and `dreams.settings.host/preview_scale`
retains scale while composing the corrected grid replacement. Motion/head/search/
pulse/FPS/feed/performance and TV claims keep stable identities and unchanged
ordinary algorithms. Full-file source bindings are refreshed; old snapshots and
passes remain historical. HC topology is unchanged; properties describe the new
clock policy. All contracts remain descriptive drafts.

Source/map identities, archived reproducer inputs/results, commands, diagnostics,
local application/UI scope and structural results are recorded in `checks.json`.
The six-second value is simulation-time warmup, not a wall-clock SLA or a change
to accepted hardware performance criteria. Physical TV and historical cadence/
collector-overhead questions remain separate.

The default full run passes 104 tests in 25 suites (GPU/UI opt-ins skipped);
the separate actual-Metal run passes all three focused tests. The local dev app
build is ad-hoc signed and left running; verification made no live control edits, and the generated font remained byte-identical
to the committed resource. Native CUA is absent in this resumed environment, and one Xcode
My Mac session attempt reports no eligible native target. Thus a real mouse click,
current view hierarchy and screenshots remain unverified. [Application scope](application-check.json)
keeps this separate from the passing renderer regression. [Reproducer results](reproducer-results.json)
retain the timeout and all three later measurements rather than discarding the
slower first process launch.
