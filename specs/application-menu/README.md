# Interactive application menu

[Contract](specs/menu.spec.yaml), [map](../hypercode/application-menu.hc),
[validation](validation/2026-10-24/README.md).

The regular macOS launch owns a standard Dreams/Edit/Window menu bar.
Settings uses Command-comma and the existing retained settings controller;
editing/window actions remain AppKit responder-chain commands. The Services
and Window submenus are registered with NSApplication. Accessory launches retain
their existing status-item behavior and do not install the main menu.
