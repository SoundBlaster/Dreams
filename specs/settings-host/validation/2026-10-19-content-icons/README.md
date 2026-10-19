# Native content setting icons — 2026-10-19

Runtime `db0d2793d624965337ac5f607fb5234a75f97517`. [Source/map identity](../../evidence/2026-10-19-content-icons/source-identity.json).

Add semantic SF Symbols to native content control labels, matching the prototype.
SettingsRowLabel uses a shared24pt icon slot, secondary monochrome rendering and
wrapping localized/verbatim text. Decorative images are hidden from accessibility.
SettingsSliderRow gains a source-compatible optional systemImage, preserving
shared label/track/readout geometry, native labels/values and caller-owned state.
Host uses icons in parameter, color, toggle, runtime, shortcut, hook and display
rows; the disposable catalog form demonstrates the same provider.

Stable NativeComponents/Forms/SettingsBinding roles retained. Provider native_controls
and host_owned_binding plus host native_controls/material_composition remain applicable.
Both packages/maps and implementation bindings repinned; the parent still owns
values, operations, settings persistence and one preview renderer. No new runtime
policy, preference or behavior. Historical evidence remains source-specific.

All selected icon names were exact-name checked with installed SF Symbols CLI
against macOS15. Two candidates unavailable under their old names were discarded,
not used. Native app release build passed (11.14s) on verifiedTB5 via SDK27/minos15 helper.
Actual geometry/AX observations are separate from structure and full VoiceOver acceptance.

[Structural log](structure.log): HC parse/profile validation and SpecPM exit0.
Known external platform-capability draft warnings retained. Tool identities: Hypercode
SHA256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`; specpm 0.2.0.
Catalog release build passed9.04s. Lint rechecked after catalog-only line wrapping.

[Exact symbol/availability results](symbols.json) preserve all icons used by the
changed host/catalog rows. `make lint` passed after formatting; known SwiftLint
unused_import configuration warning remains. No behavioral unit tests mirror these
reversible presentation changes; source review, build and actual UI are separate.

Current/snapshot identity audit: all58 source/map entries match.

## Actual UI

[Rain EN](rain-wide.png), [Appearance EN](appearance-wide.png),
[Rain RU700](rain-700-ru.png), [report](ui-report.md). Wide and compact
icon/title/track/readout alignment observed; long labels wrap without overlap.
Native controls preserve AX labels/IDs; decorative symbols add no image AX items.
General/Displays also inspected in the bounded pass. QA-only frame harness restored
source and normal binary byte-for-byte. Production prefs and system theme unchanged.
Full VoiceOver and macOS15 runtime remain unverified.
