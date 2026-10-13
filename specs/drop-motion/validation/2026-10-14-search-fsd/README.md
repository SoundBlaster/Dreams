# Search occupancy after FSD — 2026-10-14

Source `98fe537f30ef5c2f31cd7c0b22ff4ba20e82175f`; [identities](../../evidence/2026-10-14-search-fsd/source-identity.json).
Both motion/search retain stable draft claim IDs and current FSD bindings; older snapshots
and runtime observations remain historical. UI ownership is SettingsPageController/Window
with defaults in features/rain/config. PR18 is independent, not included here.

[Native settings](native.log) passed 0/37/100 percent and saved/reloaded state;
[unit target](unit.log) passed 33 tests plus standalone checks, including live quota
changes/retrigger/hide and cached-count consistency. [12 tvOS Simulator tests](tvos.log)
passed for the shared simulation. tvOS uses the shared default search policy; this change
does not add a tvOS setting or enable braking there. [Screener SDK trace](trace.log)
completed and is appearance evidence separate from control assertions.

## P2 scheduling and parity

Intermediate trials no longer trigger quota maintenance; active count is cached.
Stable timestamp/index heaps select columns and per-column trials without repeated
whole-grid/search dictionary scans. Cancellation/overwrite invalidates pending work.
The simultaneous-share, burst, ink-lifetime and independent-motion claims retain behavior.

The [witness](benchmark.swift), [before](baseline-perf.log) and [after](heap-perf.log)
compare 240×135, full density, 301 frames over five wall-clock animation seconds,
10/100 percent occupancy and 1×/3× speed. Glyph/writtenAt/changedAt FNV digests and
population/search counts match in all four cases. CPU time at 100%/3× falls from
20.07s to 1.28s (~15.7×). This is a local model-only sample, not a rendering FPS guarantee.
Native and model tests separately verify lifetimes/brightness/motion and frame subdivision.

[Structure](structure.log), [lint](lint.log), [runs](runs.json) and [tools](tools.json)
record separate checks. No domain HC rules exist; syntax/cascade is not behavior proof.
Platform capability warnings remain explicit. Physical Apple TV, monitor topology and
physical hotkey delivery are not retested. Contracts remain descriptive drafts.

[Release app](app.log), [localization](localization.log) and [MCP smoke](smoke.log)
passed on this source. [Fresh SDK settings capture](settings.png) shows the new controls;
Screener MCP is not available in this turn, so appearance is inspected from the saved PNG.

Stored runtime/build diagnostics have trailing whitespace normalized; raw local logs
remain in artifacts/pr20-fsd.
