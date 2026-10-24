# Interactive application menu

[Contract](specs/menu.spec.yaml), [map](../hypercode/application-menu.hc),
[validation](validation/2026-10-24-single-instance/README.md).

The regular macOS launch owns a standard Dreams/Edit/Window menu bar.
Settings uses Command-comma and the existing retained settings controller;
editing/window actions remain AppKit responder-chain commands. The Services
and Window submenus are registered with NSApplication. Accessory launches retain
their existing status-item behavior and initially do not install the main menu.
An exclusive accessory controller can show the GUI/main menu on an explicit reopen.

General settings now offers a saved native status-icon visibility toggle, also
available in the legacy window. It defaults to visible; hiding it retains the
status menu and stop shortcut, while interactive Settings/Dock access remains.

[Single-instance ownership](specs/instance.spec.yaml) and its
[map](../hypercode/application-instance.hc) describe one desktop owner across
installed/development copies and independent publisher-only helpers.
[Current validation](validation/2026-10-24-single-instance/README.md) separates
lease/process checks, native reopening and outstanding acceptance.
