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

## Fresh validation

- Release build passes with SwiftPM scratch/cache on verified TB5 UUID
  `04B9F65E-894C-4A7C-B517-FC542E8D8E36`. `--show-bin-path` resolves to
  `/Volumes/TB5/Developer/Builds/GitHub/Dreams-36273a9c832f69b9/swiftpm/out/Products/Release`.
  Preview bundle is under that checkout's TB5 build root; existing internal artifacts remain.
- [NativeSettingsTests](tests.log): 15 tests passed, including existing recorder and Carbon
  conflict regressions. Explicit opt-in capture is a separate run; no new full GPU-suite claim.
- `make lint` passed (FSD, SwiftLint, ruff, shell, docs). Existing SwiftLint unused_import
  configuration warning remains. [HC/SpecPM checks](structure.log) passed.
- `check-identities.py` verifies 98 current source/map and historical/new snapshot pairs.
- Actual TB5 app: CUA verified idle, recording, invalid plain A feedback and Esc cancellation.
  Both buttons and value fit one row; no clipping, duplicated feedback or saved shortcut change.
- Screener SDK 0.2.0: `make test-native-settings-trace` passed, 15 hierarchy frames in
  session `D443F316-10BE-4805-9942-9FED575C5F20`. [Timeline](timeline.jsonl), [frame hashes](frames.json).
  MCP inspected shortcut.error.narrow: controls wrap below the value; error is fully visible.
  Hierarchy capture retains known black Metal/selection/material artifacts; it establishes
  fixture layout, not compositor fidelity. Actual-app CUA is separate evidence.

Build command: `swift build -c release --scratch-path <TB5>/swiftpm --cache-path /Volumes/TB5/Developer/Caches/swiftpm`.
Test command uses the same options and `--filter NativeSettingsTests`.
The unchanged trace make target runs through a temporary PATH wrapper inserting those
same SwiftPM options; the target's scenario and assertions are preserved.
Tools: Apple Swift 6.4, Screener 0.2.0, SpecPM 0.2.0, SwiftLint 0.63.3.
No fullscreen/display topology, VoiceOver, physical TV or macOS 15 acceptance is claimed.
