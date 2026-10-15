# Startup shortcut retry — 2026-10-15

Runtime `96bda65c685ca4759e93e7fde95056b97fc237f9`. [Source/map identity](../../evidence/2026-10-15-shortcut-retry/source-identity.json).

PR #29 P2: a failed initial Carbon installation removes its event handler. Settings now
use full installation when emergencyHotkeyRegistered is false; changes to an already
registered shortcut retain the existing change/rollback path. The same recording/reset
owner serves both presentations. Saved shortcut and menu/UI update only after success.

Host shortcut_recording/overlay_exit and overlay registration_failure/callback_lifetime
claims keep stable IDs with the retry clarified. Shared SettingsPageController consumer
bindings are repinned for rain; rain timing, pulse, head, search and renderer are unchanged.
HC role/source bindings and fallible-Carbon-registration remain accurate without map edits.
No UI layout, display topology, glyph, tvOS or feature-flag changes. Draft acceptance remains.

Fresh host checks and limits: [validation](../../../settings-host/validation/2026-10-15-shortcut-retry/checks.md).
