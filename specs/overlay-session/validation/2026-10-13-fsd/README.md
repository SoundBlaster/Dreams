# PR #8 FSD integration validation — 2026-10-13

Production source: `691d94b65eb8fd1687b09cef7ff4f6f5c2776c83`. [Identities](../../evidence/2026-10-13-fsd/source-identity.json) pin FSD files/maps.
Historical evidence remains unchanged; these contracts retain descriptive draft status.
Current results below identify executed checks; source declarations alone are not test evidence. Physical Apple TV and physical keyboard
hotkey delivery are outside this pass; simulator/native target-action checks are separate.


## Fresh results

- [make test](mac-tests.log) exit 0: release app, standalone models, 17 Swift tests
  (including native settings), architecture rejection tests, localization, hooks,
  uninstall/plugins, MCP lifecycle, hook pressure, transparent alpha and column bounds.
- [Lint](lint.log) exit 0: pinned FSD gate for macOS/tvOS has zero errors/warnings;
  SwiftLint keeps its existing unused_import analyzer-rule configuration warning.
- [Settings trace](gui-trace.log) exit 0: completed Swift tests and all 13 PNG checkpoints,
  session 2B5D2BDA-FD2C-4BC6-A00A-6680E20EEF8C. Inspected separately via Screener MCP.
- [Displays](displays.log) exit 0: native settings and two rendered displays, hot-plug,
  retained windows/timer, subset/fallback, workspace exclusion and stop/expiry. This uses
  virtual display topology; it is not a physical clamshell/cable test. Launch Services
  emitted sandbox-extension diagnostics but the exercised runtime scenarios completed.
- [Exit](exit.log) exit 0: wrapper verifies native Esc/button exit across displays,
  plain click, focus return, active-display unplug and transparent input plus four
  checkpoints (F805107A-B0ED-4629-8B54-042734CF1546). The wrapper has its own completion
  markers; the Swift runner lacks a final test-pass banner, so no separate Swift pass
  is inferred for this harness.
- [Metal](metal.log) exit 0: four restored/classic × rain/keyword alpha regressions passed.
- [tvOS build](tvos-build.log) exit 0 for arm64/x86_64 simulators; [12 simulator tests](tvos-tests.log)
  exit 0 on tvOS 27, including GPU font/shader loading, whole-cell mask and density.
- [HC/SpecPM](structure.log) exit 0 for current application/editor/overlay maps and profiles;
  zero errors, prior eight glyph / eleven overlay unresolved-capability warnings retained.
  No domain HC contract rules are defined; syntax/cascade success is not behavior proof.
- [Docs](docs.log) and [whitespace](whitespace.log) exit 0.

[Commands/results](runs.json), [tools](tools.json) and the pinned source/map identity
separate runtime, structure and draft acceptance. Source relocation does not claim to
fix O1–O7. Physical Apple TV/global keyboard shortcut and actual-monitor behavior are
not retested; macOS success does not establish those profiles. PRs #18–20 remain separate.

Stored xcodebuild logs have trailing whitespace normalized; full diagnostic text is
preserved. Original raw local outputs remain in artifacts/pr8-refresh.
