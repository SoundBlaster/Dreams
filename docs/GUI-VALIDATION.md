# FSD GUI validation

## Current Metal preview trace

For a short trace of the production native settings UI and live Metal preview:

```sh
make trace-metal
```

On the configured macOS host, apply the TB5 preflight and pass the resulting
`DREAMS_SWIFTPM_SCRATCH_PATH` and `DREAMS_SWIFTPM_CACHE_PATH` as described in
`AGENTS.md` before running this build-backed command.

This opt-in scenario uses the pinned Screener 0.2.0 compositor backend and
records `metal.rain.playing`, `metal.rain.paused`, `metal.rain.resumed` and
`metal.appearance`. It requires an unlocked GUI and existing Screen Recording
permission; failures do not fall back to AppKit or capture the desktop. The
output identifies the `.vtrace` directory. With the default trace directory,
Screener MCP can find `Dreams-Metal-preview` through `screener.sessions`, then
inspect markers and frames with `screener.timeline` and `screener.frame`.
Set `DREAMS_LANGUAGE` to `en` or `ru` as needed. The scenario drives the model
programmatically in a test host with an isolated feed and restores saved
preferences. It does not record an independently running app or verify physical
inputs. Use `DREAMS_TRACE_DIRECTORY` only if the MCP reader is configured to
read that directory.

The following earlier records describe their original versions and remain
historical evidence.

Local validation on 2026-10-12 (Europe/Moscow), macOS 27.0 (26A428),
arm64, Swift 6.4, Xcode 27, built-in Retina display (1512 × 982 points).
Production code tested: PR #8, commit `74405855b6081faaa6626b5eb32f1934327428fe`.
The additional changes in this test pass affect only the test dependency, harness and documentation.

## Reproduce the settings trace

```sh
DREAMS_LANGUAGE=en make test-gui-trace
DREAMS_LANGUAGE=ru make test-gui-trace
```

ScreenerKit is pinned to `0.1.0`, revision
`fd6cc12f37c875ed57f62454318363cbf3de8705`, and linked only into `DreamsTests`.
It is not linked into the Dreams application. The connected local Screener MCP reader
comes from `~/Development/GitHub/Screener` (checkout `d16d63d`; its existing unrelated
documentation changes were preserved).

The harness uses a disposable agent feed and restores its test process's settings.
It sends native AppKit target/action messages, rather than desktop clicks.
The wrapper requires a completed scenario, 13 saved PNGs and `sessionEnded`,
in addition to Swift Testing's exit status. A prematurely exiting runner is a failure.

| Scenario | Checks |
| --- | --- |
| Columns | Manual 24 and 240; automatic mode disables its slider |
| Sliders | Both ends of density, speed, fade, brightness spread, glow, idle intensity and keyword brightness |
| Colors | Rain and keyword color actions update the controller |
| Background modes | Separate rain colors and glow persist across mode switches |
| Run time | Every choice updates the model; transparent mode disables the control |
| Checkboxes | Screenshot hiding and restored glyphs update the model |
| Shortcut recorder | Recording starts; pressing its button again cancels without replacing the shortcut |
| Agent feed | Working → idle updates both status and label |
| Window lifecycle | Close/reopen reuses the window and timer |
| Defaults/cleanup | Model defaults synchronize controls; timer and focus observer are removed |

Completed traces live under `~/Library/Caches/Screener/Traces/`:

- English: `AB507965-2331-48DF-9899-08DD0F2C0F3B` (all settings scenarios).
- Russian: `2772B317-2A70-4333-983B-4F1670C9BFBF` (also tests keyword color and all run-time choices).

The initial English trace `77945394-8C57-42E7-94CF-A79CE683A40E` was inspected through Screener MCP's sessions → timeline → contact sheet → frame.
Each AppKit PNG is 936 × 1714 pixels at 2× scale. The completed timeline contains
29 records: start, 13 marker/frame pairs, cleanup marker and end; no error marker.
These are view captures: they validate content/layout, not compositor blur or live Metal pixels.

## Application runtime

`zsh scripts/build-app.sh release` built and ad-hoc signed `dist/Dreams.app`.
Native CUA actions against that bundle verified:

- Start in transparent mode: status advanced through 101 and 220 rendered frames.
- Stop button: status changed to stopped.
- Start on black: 82 frames, then Escape changed status to “Stopped with Esc”.
- Mode switching restored the original separate rain color and glow.
- Closing and reopening through Finder preserved transparent rain (417 frames).
- Closing and reopening on black stopped rain with the explicit reopen reason.
- Quit during animation terminated PID 39162; a CUA observation relaunched it with rain stopped.
  A second Quit without another CUA observation left no Dreams process.
- Reset confirmation appeared; Cancel preserved settings.
- Shortcut recording appeared; Escape cancelled it. The original combination was recognized.

The original transparent mode and parameter values were restored, with rain stopped.
Agent hook installation buttons were not pressed against the user's real configuration.

`python3 scripts/smoke.py` passed MCP initialization, invalid inputs, cross-process keywords,
hook lifecycle, expiry, virtual workspace creation/cleanup, changing Metal previews,
prepare/resume and timer stop. `.venv/bin/python scripts/test-transparent.py` passed:
opaque alpha is 255 throughout; transparent alpha spans 0–255 with partial glyph edges.
The actual application lifecycle supplies the event loop for those checks.

## Remaining checks before merge

- Global Carbon shortcut: CUA delivered the expected modifiers to the shortcut recorder,
  but its synthetic combination did not stop the running rain, including after re-registration.
  This remains **unconfirmed**: distinguish injected event routing from a physical keyboard
  failure before changing the hotkey implementation. Verify ⌃⌥⌘D with Dreams inactive too.
- No performance, multiple-monitor transition or compositor-material fidelity claim is made.

An initial attempt to run MTKView lifecycle inside the async Swift Testing host exited
without a final test result or `sessionEnded`; a synchronous event pump also produced zero
rendered frames. Those partial traces are not passing evidence. The committed trace
scenario intentionally covers settings only; live rendering is checked in the application.

PR #8 remains unmerged pending the remaining runtime checks.


## Combined macOS/tvOS branch rebase (2026-10-12)

PR #9 was merged into PR #8, then the combined branch was rebased onto
`f1d33b5` (main, Dreams 0.1.5). This pass validates the combined production
sources at `aa8fb3b`; the follow-up changes only remove an extra blank line
and record this evidence.

The rebase keeps main's display selection, multi-display overlay lifecycle,
opaque Esc/button exit, transparent alpha compositing, stretching trails and
hook labels typed from row zero. Display controls live in the settings page;
display state and overlay lifecycle live in the rain feature.

Fresh local checks passed:

- `make lint` and architecture gate regression checks.
- `make test`: macOS app build, simulation/settings tests, localization,
  hook install/uninstall, plugins, MCP smoke, hook pressure, transparent alpha
  and column bounds/rendering.
- `make test-gui-trace`: all 13 settings checkpoints. Trace
  `0F1BC070-5852-4E8A-9873-66822B2D31F3`, inspected with Screener MCP.
  The captured settings page includes the display selection controls.
- `make test-exit`: Esc/button stop all overlays, ordinary clicks keep rain,
  previous focus restores, unplugging the active display chooses a surviving
  overlay, and transparent overlays remain click-through. Four checkpoints:
  `5C28C402-8218-467B-B3C0-7C2B1E0C0369`.
- `DREAMS_TEST_METAL=1 swift test -c release --filter TransparentFadeRenderingTests`:
  all four rain/event and restored/classic font cases passed on the local GPU.
- `make app-tv`: universal Apple TV simulator build passed.
- `make test-tv TV_DEVICE=B29EC156-5EF9-4A56-8147-1C98D4E228DB`:
  12 tests passed on the tvOS 27 simulator, including the font/shader GPU load,
  whole-glyph clock mask and continuous full-density occupancy.

This pass does not retest the physical Apple TV or the physical-keyboard global
Carbon shortcut. The older shortcut uncertainty above remains open; simple Esc
and the overlay exit button have separate passing native lifecycle checks.

## Merge readiness refresh — 2026-10-13

PR #8 rebased cleanly onto main `85e3aee`; production/test baseline `691d94b`.
Full macOS test/lint, 13 settings checkpoints, display/exit wrappers, four GPU alpha cases,
universal tvOS simulator build and 12 tvOS tests passed again.
[Current source identities and validation](../specs/overlay-session/validation/2026-10-13-fsd/README.md)
keep old runs historical and update FSD paths/cleanup ownership. Physical Apple TV and
physical global-shortcut delivery remain outside this pass.
