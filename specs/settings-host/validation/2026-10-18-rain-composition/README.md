# Rain composition pilot — 2026-10-18

## Change and contract impact

Rain retains one native grouped Form and the existing model bindings. Its localized
title/description scroll with the first section header; Grid, Motion and Searching
remain native groups. The search explanation moves to a native section footer.
The outer rounded material card is replaced by a rectangular regular-material
foundation; the open preview gains a noninteractive outline and 12-point inset.
The rest of the native sections retain their existing panels. Shared controls use
system green tint; native sidebar selection remains OS-owned.

System appearance is inherited, with no new preference or theme setting. The one
renderer, 100% display crop, preview lifetime, existing saved values and default-off
launch flag are unchanged. No library API, catalog runtime or renderer source changed.

Host material_composition is revised in draft.6 to describe the Rain pilot. Stable
native_controls, one_settings_owner, default_off, independent_preview, preview_scale
and preview_lifetime claims retain their requirements. Catalog host_owned_binding,
native_controls and platform_availability remain applicable with their existing
source baseline: no fresh catalog behavior or acceptance is claimed. HC responsibility
identities are preserved; Forms/LivePreview composition properties are refreshed.
[Source/map identity](../../evidence/2026-10-18-rain-composition/source-identity.json) pins runtime `e86996b8da2e91c3b16083286e60bbd7cf984ab6` and later map bytes.
Formal contract and visual acceptance remain separate from local verification.

## Actual application observations

Actual app screenshots are from the isolated `ru.egormerkushev.dreams.parity-en`
release bundle, with a temporary language environment and isolated feed directory.
The captured window was 1000×800 points, not the planned 1000×720 geometry.

- [EN light](en-light-wide.png), [EN dark](en-dark-wide.png) and [RU dark](ru-dark-wide.png): title, three groups,
  values and preview are readable; the unexpected fixture band does not cover content.
- Pause/Play changed its accessible label and was restored to playing.
- [Reduce Transparency](ru-reduce-transparency.png) and
  [increased contrast](ru-increased-contrast.png) produced opaque readable surfaces.
  Both system preferences were initially off and restored to off after observation.
- The diagnostic bundle had an old NSRequiresAquaSystemAppearance override absent
  from production Info.plist. Removing it and re-signing only that bundle enabled
  the actual RU dark observation. A subsequent EN dark relaunch was killed with
  SIGKILL/137 despite signature verification; cause is unknown. This is not recorded
  as an EN-dark app pass. A fresh copied bundle with a unique diagnostic ID then
  launched successfully in EN dark using only a process launch argument; the older
  SIGKILL did not reproduce. App-specific appearance overrides were removed afterwards.
- [Operator report](actual-app-report.md) retains paths and limits. CUA edge dragging
  did not achieve a narrow actual window; narrow coverage below is fixture layout.

## Checks and evidence limits

- Settings suite: [log](settings-tests.log), exit 0, 16 tests passed. Preview unit suite:
  [log](preview-tests.log), exit 0, five selected tests with two opt-in Metal cases skipped.
  The [explicit Metal run](metal-tests.log) enables and passes those two lifecycle tests.
- EN/RU `make test-native-settings-trace`: [EN log](trace-en.log) / [manifest](trace-en-manifest.json)
  and [RU log](trace-ru.log) / [manifest](trace-ru-manifest.json) record 27 frames
  each. Window-frame dimensions are explicit, including 560×450 light/dark and large
  text. Hierarchy frames establish layout, not compositor fidelity or actual keyboard/
  VoiceOver input. Offscreen controls remain scrollable; snapshots do not prove all
  offscreen pixels. RU minimum-window examples: [light](ru-rain.minimum.light.png),
  [dark](ru-rain.minimum.dark.png); these retain known hierarchy material/selection artifacts.
- A [ScreenCaptureKit attempt](compositor-attempt.log) failed before producing a
  completed trace marker. The Make verifier correctly failed. It is not narrow-window
  compositor evidence; fixing that capture path and the deferred band is outside this pilot.
- [Lint](lint.log), [localization](localization.log), [source identity](identities.log)
  and [HC/SpecPM structure](structure.log) passed. Tools: Swift 6.4, SpecPM 0.2.0,
  Hypercode SHA256 6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
  Existing unresolved external capability warnings are descriptive-draft dependencies.
- Builds/tests use verified TB5 APFS UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36,
  checkout key Dreams-36273a9c832f69b9. The Make trace entrypoint uses a temporary Swift
  wrapper with explicit scratch/cache paths. No cache migration, CI watch or release.

Next: owner visual acceptance of Rain, then reuse the composition for other sections.
Keyboard/VoiceOver, macOS 15 physical runtime and narrow compositor acceptance stay open.
