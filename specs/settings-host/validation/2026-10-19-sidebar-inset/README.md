# Sidebar branding top spacing — 2026-10-19

Runtime `a43e644e031f57ac77dad8ea84eb2489bdacd8bf`. [Pinned source/map baseline](../../evidence/2026-10-19-sidebar-inset/source-identity.json).

Remove the extra44pt top padding above the brand. The native system safe-area
spacing remains; no negative inset or ignored sidebar safe area is introduced.
The icon/header/list move upward together, preserving the native window controls.
This minor layout change keeps draft.14 native_controls/material_composition and
Navigation/Forms roles applicable: brand, permanent sidebar, native selection,
glass, window lifecycle and preferences are unchanged. No cosmetic contract/map
edits or version bump; implementation binding/source identity are refreshed.
Historical old-spacing screenshots remain attached to their original baseline.

[Release build](app-build.log) and [lint](lint.log) passed. All57 current/snapshot
source/map hashes verified. [Structure](structure.log) records HC/SpecPM checks.
No new static-view unit tests; earlier suite passes are not relabelled. Physical
macOS15, narrow resize, full VoiceOver and dragging remain unverified. No release
or CI waiting. Swift6.4, SpecPM0.2.0; Hypercode SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.

## Current visual observation

[Actual wide window](wide.png) shows the brand shifted upward44pt at the same
1000×720 window size, reducing the visible top gap approximately by half relative
to the preserved fixed-sidebar screenshot. Complete title/subtitle and seven rows
remain visible, with native safe-area spacing retained. The capture privacy badge
covers system window-button pixels; no visual button pass is inferred.
