# Active rain color window tint — 2026-10-18

Runtime `b4a16c45ab07a57adf5fd9723cb777c5668943de`. [Source identity](../../evidence/2026-10-18-rain-tint/source-identity.json)
pins the changed native page and HC composition plus unchanged dependency snapshots.

Host material_composition is revised in draft.10: NavigationSplitView uses the active
rain color as tint; native NavigationLink rows use listItemTint for Label icons.
Color edits and transparent/opaque profile switches use the existing observed model
and controller notifications. No extra preference, renderer, global macOS accent
change or custom sidebar selection drawing. Native selection appearance remains
platform-owned. one_settings_owner/default_off/native_controls remain applicable;
the settings-catalog provider source and contract are unchanged.

Verification: SDK27-linked macOS15-minimum release build passed. Existing settings
tests, lint, structural validation and actual UI observations are recorded below.
The known upper toolbar blur band remains deferred. No macOS15 physical, full
VoiceOver, keyboard navigation, release or CI acceptance is claimed.

## Results

- [Actual SDK27 UI](red.png), [report](ui-report.md): blue opaque → red transparent →
  blue opaque updates rain, sliders, toggles and all sidebar symbols live. Native
  selected-row highlight remains neutral/platform-owned. Isolated QA defaults only;
  production and the owner's interactive QA preferences were preserved. ColorPicker
  panel interaction was not completed by automation; profile switching exercised
  the same observed active color getter.
- [Settings tests](settings-tests.log): 16 tests passed, conditional preview/trace
  cases skipped as recorded. Final release build passed in 11.12s.
- make lint passed (existing SwiftLint unused_import configuration warning).
- [HC and SpecPM structure](structure.log) passed with existing draft external
  capability warnings; source hashes verified against the current baseline.

Tools: Swift6.4 / Testing2084, SpecPM0.2.0 and Hypercode binary
SHA2566503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Build outputs use verified TB5 checkout scratch; no release or CI waiting.
