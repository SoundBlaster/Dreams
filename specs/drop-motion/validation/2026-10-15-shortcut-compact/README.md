# Compact shortcut row — 2026-10-15

Runtime `0eb39ff4826f71f7739100671f8faf889e718a88`. [Source/map identity](../../evidence/2026-10-15-shortcut-compact/source-identity.json).

Only NativeSettingsForms.swift changes: native shortcut value/actions share one row,
with a vertical fallback at insufficient width; caption-sized guidance and recording/error
feedback share the same group. Duplicate label and separate explanation rows are removed.

Stable host native_controls, shortcut_recording, overlay_exit, one_settings_owner,
default_off and material_composition claims retain their meanings. SettingsPage native
presentation consumes the same recorder/model; maps and ownership boundaries are unchanged.
The pulse settings consumer shares this file, but NativeAppearanceForm and all rain bindings
are byte-for-byte unchanged. Overlay handlers and tvOS/glyph/catalog implementations are
unchanged. Prior acceptance remains descriptive draft; old tests are historical.

Fresh shared UI and structural checks: [host validation](../../../settings-host/validation/2026-10-15-shortcut-compact/README.md). No new rain GPU behavior claim.
