# Sidebar rows and stable preview alignment — 2026-10-19

Runtime `d93aca41f28560a6e5de943f830de80b89cdcbc5`. [Source/map baseline](../../evidence/2026-10-19-sidebar-rows/source-identity.json).

Host material_composition draft.15 folds two presentation changes into existing
Navigation/LivePreview roles. Native Label/NavigationLink rows use body text,
large monochrome SF Symbols in24pt slots, content minheight32pt and native insets
6pt vertical/12pt horizontal. Inactive icons use semantic primary tint; the selected
icon retains active rain color. Native selection/background/input remain platform
owned; no custom selection drawing or replacement navigation control. Native
List minimum-row environment alone did not enlarge the macOS sidebar, so final
sizing belongs to Label content. The old gray/compact candidate is not final QA.

The owner reported only Live Preview shifting downward on Rain. Source had a12pt
padding conditional on outlined, used only by Rain. Remove that section-dependent
padding; the outline remains an overlay which does not affect layout. Header,
footer and pane width now use the same layout on every section. No renderer/time,
reference viewport, shared provider, persistence or window lifecycle change.

Stable native_controls/material_composition/preview_scale/preview_lifetime and
one_settings_owner obligations retained; implementation bindings repinned. Earlier
suite/screenshots remain on their original baselines. Actual alignment checks are
separate from structural validity and general rendering tests. Physical macOS15,
narrow resize, window dragging and full VoiceOver remain unverified. No release
or default-on rollout/CI waiting.

## Local validation

[Release build](app-build.log), [lint](lint.log) and [HC/SpecPM](structure.log)
passed. All57 current/source snapshot hashes verified. Known SwiftLint unused_import
configuration and descriptive-draft external capability warnings remain. Tools:
Swift6.4, SpecPM0.2.0; Hypercode binary SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Verified TB5 checkout scratch; active SDK27/minos15 linker guard.

[Current settings suite](settings-tests.log):16 tests passed; conditional renderer/trace
cases remain skipped as logged. General tests do not establish preview chrome geometry.

## Actual final combined QA

[Appearance](appearance.png), [Rain](rain.png), [report](ui-report.md): header top,
header width and footer position/width remain the same across the two sections.
The Rain outline stays visible. Rows are visibly more spacious, all seven entries
fit, selection/content and active-icon accent move correctly. Inactive icons still
render gray under the native sidebar style despite semantic-primary tint; do not
claim pure white matching. No custom native selection replacement was introduced.
Production/system preferences were preserved. This actual profile is distinct
from physical macOS15, narrow resizing and full VoiceOver acceptance.
