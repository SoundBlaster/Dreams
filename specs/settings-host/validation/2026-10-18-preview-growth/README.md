# Extra width belongs to preview — 2026-10-18

Runtime `cab0e76da217f889450df8f372e08e094e973e03` caps wide native forms at 480 points. With detail width at least
700 points, the form uses min(480, detailWidth − 48 − 240); the preview receives
the remaining space with a 240-point minimum. Outer insets and spacing stay 16.
Narrow layouts retain the existing vertical composition. One renderer and its 100%
display crop are unchanged: a larger opening exposes more rain rather than scaling it.

Host draft.7 clarifies the existing independent_preview assembly obligation. Stable
native_controls, material_composition, preview_scale, one_settings_owner and default_off
requirements remain. No catalog/UI library or renderer source changes; their prior
baselines are retained. [Current identity](../../evidence/2026-10-18-preview-growth/source-identity.json)
pins source and separately changed map bytes. Earlier Rain evidence stays historical;
no old test results are relabeled as fresh application checks.

## Fresh verification

- Actual isolated app: native Zoom changed the window from 1000×800 to 1464×949pt.
  Settings foundation stays approximately 480pt wide; open preview grows from about
  251 to 715pt, based on screenshot pixel edges. Labels/readouts remain aligned and
  glyph scale is visually unchanged. [Before](actual-baseline.png),
  [after](actual-expanded.png), [operator report](actual-app-report.md).
  Measurements are screenshot estimates, not instrumented runtime frames.
- [EN](trace-en.log)/[manifest](trace-en-manifest.json) and
  [RU](trace-ru.log)/[manifest](trace-ru-manifest.json) Make trace checks: exit0,
  29 hierarchy frames each, including 1440pt light/dark and exact 560×450pt window
  frames. [Expanded RU fixture](ru-expanded-hierarchy.png) verifies allocation;
  hierarchy materials/selection/Metal artifacts remain capture limitations.
- [Lint](lint.log), [structure](structure.log) and [hash checks](identities.log)
  are separate from actual UI and acceptance. Toolchain: Swift6.4, SpecPM0.2.0,
  Hypercode SHA2566503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
  Known unresolved external capability warnings remain draft dependencies.
- Verified TB5 UUID04B9F65E-894C-4A7C-B517-FC542E8D8E36, checkout build key
  Dreams-36273a9c832f69b9. Make trace uses an external Swift scratch/cache wrapper.
  No preferences, overlays, fullscreen, glyph files, CI watch or release changes.

Prior [Rain composition validation](../2026-10-18-rain-composition/README.md) records accessibility
and unit/Metal lifecycle evidence on its own revision. Narrow compositor, keyboard/
VoiceOver and macOS15 physical acceptance remain open; specification acceptance is draft.
