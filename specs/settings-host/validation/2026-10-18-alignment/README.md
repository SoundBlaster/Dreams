# Shared slider columns — 2026-10-18

Runtime source `07e7d5723ce03a34524443c40342354a6adce65e`.
[Current host identity](../../evidence/2026-10-18-alignment/source-identity.json) and
[catalog identity](../../../settings-catalog/evidence/2026-10-18-alignment/source-identity.json).

## Change and impact

Each former LabeledContent row allocated its label and readout independently. A long
label or a different unit changed its slider endpoints. SettingsSliderRow now uses
system HStack/frame layout: equal flexible label/track columns and one shared 80-point
readout column scaled relative to body text. Titles wrap vertically. Digits remain
monospaced and values align to the trailing edge; the native Slider still owns input,
localized accessibility label, supplied accessibility value and identifier.

The fix is in the shared DreamsSettingsUI library, so both the production native host
and catalog consume it. There are no custom slider gestures, styles or layout engines.
System Form/Section cards, separators and semantic state remain host-owned.
At equal content width and text scale, row allocation is independent of title/readout
length. The app's current EN/RU units fit the reserved value column; this is not a
promise about arbitrary future caller-supplied unit strings or languages.

Affected catalog claims: native_controls, host_owned_binding, platform_availability;
parent host native_controls/one_settings_owner/default_off/material_composition remain
applicable. The catalog composition HCS string is updated from LabeledContent to HStack
columns, with stable role IDs. It is pinned as a dirty map prepared after the runtime
commit; source snapshots match the runtime commit. Current host/catalog identities
are repinned. Other subsystems keep their historical baselines and are not revalidated
by this layout pass. No controller, renderer, hooks, display, font, TV or flag changes.
The catalog contract remains descriptive draft.5; acceptance remains separate.

## Fresh verification

- [Release app build](build.log): exit 0, Swift 6.4, arm64 macOS 27.
- [Standalone catalog product](catalog-build.log): exit 0 with warnings-as-errors,
  macOS 15 deployment. This is a product build, not a new packaged/installed catalog check.
- `make test-native-settings-trace` with DREAMS_LANGUAGE=en/ru: exit 0 for each,
  22 hierarchy frames per language, 44 total ([EN](trace-en.log), [RU](trace-ru.log)).
  All seven sections remain present at 1000 and 560 points. Native snapshots are
  programmatic states, not keyboard/device interaction evidence.
- Visually inspected Rain/Appearance wide and narrow: shared track endpoints and
  right-aligned readouts, no title truncation. Representative narrow frames:
  [EN Rain](en-section.rain.narrow.png), [RU Appearance](ru-section.appearance.narrow.png).
  Existing black preview/selection/slider artifacts in hierarchy capture remain
  capture limitations; no Metal/glass fidelity claim is derived from these frames.
- Actual isolated EN app: Appearance and Rain tracks share visual endpoints (approximately
  x846–1138 screenshot pixels), readouts align at approximately x1316, and the long
  Glyph brightness pulse label is readable. Slider AX labels/IDs/values are retained.
  Glow Increment 57% → 58% and Decrement → 57% work in isolated preferences.
- [Lint](lint.log): exit 0; known unused_import SwiftLint configuration warning remains.
- [HC/SpecPM](structure.log): exit 0, existing unresolved external-capability warnings
  remain descriptive dependencies. Hypercode executable SHA256
  6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f;
  SpecPM 0.2.0. Current source/map/snapshot checks: [identities](identities.log).

Trace locations and frame hashes: [EN](trace-en-manifest.json), [RU](trace-ru-manifest.json).
App SwiftPM output is on verified TB5 key Dreams-36273a9c832f69b9; standalone catalog
uses DreamsSettingsUI-2974814faa88bdee. APFS UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36.
The preserved Make trace entrypoint uses a temporary PATH wrapper to pass external
scratch/cache paths. Python/ruff/Clang caches are also external. No migration or cleanup.

Full VoiceOver/Tab traversal, physical macOS 15, increased system text size and
actual-app narrow interaction remain unverified. No full GPU suite, CI result,
release or default enablement is claimed. Toolbar blur remains deferred.

Every source snapshot was additionally compared byte-for-byte with the pinned Git runtime revision: pass.
