# Menu-bar visibility impact — 2026-10-24

Runtime/test source: `f979c8c7d454589d225de75911c5fcdfe262c8b8`. New snapshots are identified in
[the source identity](../../evidence/2026-10-24-status-icon/source-identity.json).

`dreams.settings.host/menu_bar_icon` adds the localized native General toggle
and equivalent legacy checkbox. `one_settings_owner`, `operation_semantics`,
`lifetime` and `explicit_legacy_access` retain the existing owner/notification
paths. EN/RU labels and help identify how to reopen settings while hidden.
The production delegate applies the saved preference to the existing native item;
there is no separate preference model or shortcut reinstallation.

See [executed checks](../../../application-menu/validation/2026-10-24-status-icon/README.md).
Preview playback, accessibility motion defaults and renderer algorithms were not
changed by the menu-bar preference. A separate owner report about paused preview
is investigated through native observation; an overlay Stopped status is not the
preview playback state.
