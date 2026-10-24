# Menu-bar visibility impact — 2026-10-24

Runtime/test source: `f979c8c7d454589d225de75911c5fcdfe262c8b8`. New snapshots are identified in
[the source identity](../../evidence/2026-10-24-status-icon/source-identity.json).

`dreams.desktop.main_menu/status_item_visibility` describes the saved native
status-item presence. Main-menu installation remains interactive-only. Hiding
uses the existing item without changing menu actions, overlay lifetime or stop
shortcut registration. Settings remains reachable through the main menu and Dock.
Default/reset is visible; accessory setup reads the saved value. Cross-process
live preference synchronization is outside this change.

The focused native regression checks missing-key default, hidden startup, repeated
hide/show on the same item, reload persistence, retained menu/shortcut registration,
reset and native/legacy synchronization. Full-suite, packaged app and structural
results are recorded in results.json after execution. GUI observations are separate
from unit expectations and source reasoning.

## Executed verification

[Results and artifact/tool identities](results.json) record 91 reported tests in
22 suites, the packaged app build, EN/RU 191-key parity, lint, HC/SpecPM checks
and [235 current binding comparisons](bindings.json). Opt-in GPU/UI tests remain
skipped; unresolved external-capability warnings remain structural limitations.

The delegated native CUA walkthrough raised the fresh TB5 app. The General switch
changed ON → OFF → ON in AX and screenshots. While OFF, Dreams → Settings…
returned to the same window with the setting still OFF. It was left ON. App-only
captures do not expose the right system status bar, so actual status-icon pixels
were not independently observed; native NSStatusItem.isVisible is covered by the
focused production-delegate test. /Applications was not replaced.

Two foreground screenshots showed different rain glyph positions/content and
Pause preview; no playback toggle was required. The old test copy looked frozen
before replacement, but its exact historical pause cause is not established.
The menu-bar change does not modify preview playback or OS motion preferences.
