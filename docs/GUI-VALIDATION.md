# FSD GUI validation

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
