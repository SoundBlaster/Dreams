# Menu-bar visibility impact — 2026-10-24

Runtime/test source: `f979c8c7d454589d225de75911c5fcdfe262c8b8`. New snapshots are identified in
[the source identity](../../evidence/2026-10-24-status-icon/source-identity.json).

Refreshed current bindings for `dreams.rain.search_occupancy`, `dreams.rain.glyph_pulse`, `dreams.rain.drop_motion`.
The affected full-file snapshots include a new macOS UI preference, localization
or settings binding only. Their motion, search, pulse, display/session/exit and TV
algorithms retain their existing implementations and stable claim IDs. No
historical execution pass is relabelled for this revision. The new macOS Release
suite is relevant shared regression evidence; TV device behavior/performance is
not newly established by this macOS task.

See [current macOS checks](../../../application-menu/validation/2026-10-24-status-icon/README.md).
