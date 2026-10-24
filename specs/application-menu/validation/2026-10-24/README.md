# macOS main menu — 2026-10-24

Cause: setupMenu built only NSStatusItem.menu. The interactive entry point used
a regular NSApplication, but no mainMenu was assigned, producing an empty system
application-menu placeholder. Native menus are now installed before the settings
window opens, through the guarded will-finish-launching delegate callback.

Two focused tests verify native application actions and Settings dispatch plus
editing/window target/action/key-equivalent routing. A full Release suite,
localization/lint/structure, packaged app build and bounded native UI observation
are recorded in results.json after execution. No tvOS behavior is changed.

The existing build wrapper now accepts DREAMS_GLYPH_OUTPUT. This run used the
verified checkout-specific TB5 paths for glyph generation, SwiftPM products and
app output. The bundled font remained byte-identical in git. No primary checkout
glyph checkpoints or installed /Applications app were changed.

## Native UI observation

The primary agent launched the exact TB5 app copy and inspected native AppKit
accessibility through CUA. Dreams/Edit/Window were present. Opening Dreams showed
About, Settings, Services populated by macOS, Hide/Hide Others/Show All and Quit.
Opening Window showed native Close/Minimize/Zoom/Bring All to Front plus system
placement commands and the Dreams window entry. Choosing Settings returned to
the visible `dreams.native-settings` window. Menu item shortcuts/targets are
covered by unit tests; close/reopen and shortcut keyboard behavior were not
independently established by the GUI observation. No screenshot pixels were returned.

The earlier delegated UI attempt did not run; the direct native AX walkthrough
above is the executed observation. The test app is left running. No release or
replacement of `/Applications/Dreams.app` was performed.
