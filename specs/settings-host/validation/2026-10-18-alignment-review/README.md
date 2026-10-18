# PR #31 P2: usable slider width — 2026-10-18

Runtime `d4b2d40745d31e1d862bb374c2b8e876efe7c13d`.
[Host source/map identity](../../evidence/2026-10-18-alignment-review/source-identity.json),
[catalog identity](../../../settings-catalog/evidence/2026-10-18-alignment-review/source-identity.json).
Review: https://github.com/SoundBlaster/Dreams/pull/31#discussion_r4304876138.

ViewThatFits retains the horizontal three-column composition when it fits. It moves
labels above the control row when narrow, then stacks readouts if necessary. The native
Slider has a 120-point minimum in every candidate. Readouts reserve a text-scaled minimum
rather than concealing their intrinsic text width, and the final stacked readout wraps.
No range, Binding, formatting, preference, native input behavior or flag changes.

Catalog host_owned_binding/native_controls/platform_availability and parent host
native_controls/one_settings_owner/default_off/material_composition remain applicable.
Draft.6 clarifies the adaptive exception to horizontal alignment rather than allowing
controls to collapse. Stable role/claim IDs remain. HCS updates the existing composition
string; no new boundary. Source snapshots match the runtime commit; the new map bytes
are pinned separately as a post-runtime dirty map. Prior source and UI evidence remains
historical, including the previous live-app interaction pass. Other subsystems are unchanged.

## Fresh checks and limits

- [EN](trace-en.log) and [RU](trace-ru.log) `make test-native-settings-trace`: exit 0,
  24 frames each, including Appearance and Rain at width 560, accessibility5 environment
  and explicit 32-point font. The runner verifies named large-text cases and frame files.
- Direct PNG inspection confirms the visible large-font rows stack and retain usable
  tracks: [EN Appearance](en-appearance.large-text.narrow.png),
  [RU Rain](ru-rain.large-text.narrow.png). Long forms scroll below the screenshot;
  this does not establish physical keyboard/VoiceOver, all offscreen row pixels or
  actual OS text-scaling behavior. Hierarchy black Metal/selection/slider artifacts remain
  capture limitations, separate from layout.
- The accessibility5 environment alone did not visibly enlarge all text on this macOS
  host, so the fixture explicitly sets a 32-point font to stress available space.
- An exploratory in-process NSAccessibility traversal returned no slider nodes on both
  old and new layouts. Its assertion failed because the tree was empty, not because of
  measured widths; it was removed. [Probe log](ax-probe.log) is preserved as a failed
  harness experiment, not red/green regression proof. There is no automated frame-width
  assertion or new live-app input claim in this fix.
- [Catalog release product build](catalog-build.log), warnings-as-errors: exit 0.
  [Lint](lint.log): exit 0, known unused_import configuration warning remains.
- [HC/SpecPM structure](structure.log) and [source/map identity checks](identities.log)
  are separate from visual acceptance. Existing unresolved external capability warnings
  remain draft dependencies. Hypercode SHA256 6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f;
  SpecPM 0.2.0; Swift 6.4 / Testing 2084.

Trace locations/frame hashes: [EN](trace-en-manifest.json), [RU](trace-ru-manifest.json).
Verified TB5 APFS UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36; worktree scratch/cache key
Dreams-36273a9c832f69b9, separate nested catalog key DreamsSettingsUI-2974814faa88bdee.
The Make trace entrypoint was preserved with a temporary Swift PATH wrapper. Python,
ruff and module caches use the SSD. No migration, new installation, CI watch or release.
New settings remain default-off; toolbar blur is deliberately deferred.
