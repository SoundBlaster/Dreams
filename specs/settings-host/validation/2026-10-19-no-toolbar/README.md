# Toolbar-free native settings — 2026-10-19

Runtime `848a64dc79c7a4d5001095e8131dc79445f9ad86`. [Source/map baseline](../../evidence/2026-10-19-no-toolbar/source-identity.json).

Host native_controls is revised in draft.12. NativePresentation/Navigation/Forms
roles retain identity; windowToolbar visibility is hidden with the system API.
The NSWindow remains titled/closable/miniaturizable/resizable with full-size content,
hidden title, transparent titlebar and native background dragging. A clear sidebar
header uses WindowDragGesture. The app title remains the accessible window title.
Section headings now live inside panels; Rain retains its scrolling heading.

Sidebar List/NavigationSplitView selection and state remain native. A localized
standard button toggles all/detailOnly and supplies Control-Command-S. When hidden,
a detail-side button provides recovery and32pt top content padding protects the
window controls. Other controls, glass, rain100% scale and default-off routing are
unchanged. The catalog provider source/contract stays on its previous baseline.
No custom window buttons, navigation list implementation or saved preference added.

Affected native_controls/material_composition/lifetime/shortcut_recording claims
retain their prior obligations. New actual observations are separate from source
review and structural validity; prior toolbar-band evidence remains historical.
No physical macOS15, full VoiceOver or release acceptance is claimed.

## Local checks

[Release build](app-build.log), [16 settings tests](settings-tests.log),
[lint](lint.log), [156 matching bilingual keys](localization.log) and
[HC/SpecPM](structure.log) passed. Conditional compositor/trace tests remain skipped
as logged. All57 live/snapshot source and map hashes verified.
Swift6.4/Testing2084, SpecPM0.2.0; Hypercode binary SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Outputs use verified TB5 checkout scratch and shared cache. No CI waiting/release.

## Actual normal SDK27 QA

[Final wide window](wide.png), [report](ui-report.md) and [recovered selection AX](recovered-ax.txt).
The toolbar/automatic sidebar item and upper blur band are absent; Rain and Live
Preview headings are visible. Exactly one localized Toggle sidebar button remains.
Hide → Control-Command-S restores the sidebar with the Rain selection. Product and
QA binary hashes matched before ad-hoc signing; resources were refreshed as well.
System close/minimize/fullscreen controls exist in AX; the capture tool's purple
privacy badge obscures their pixels. Do not claim a visual traffic-light pass.
Narrow560×450 and window dragging were not exercised in this pass; implementation
uses native APIs but their actual behavior remains a manual acceptance item.
No physical macOS15, full VoiceOver or changed accessibility-setting pass claimed.
Previous duplicate-toggle screenshots describe discarded candidates; removal must
be applied to the sidebar owner as well as the enclosing split view.
