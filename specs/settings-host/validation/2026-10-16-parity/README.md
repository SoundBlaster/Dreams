# Native settings parity — 2026-10-16

Source `c7da63dbc30ced3712ea9e5d357be6737791128a` follows merged main `4d50110`.
[Source/map identities](../../evidence/2026-10-16-parity/source-identity.json).

Two presentation defects were found and corrected: hook actions were visually present
but absent as individual accessibility buttons, and the English Codex hook status was
truncated at 560 points. Explicit accessibility containment preserves Button children;
vertical intrinsic sizing lets the status remain readable. Hook operations are unchanged.
Every section now has a wide and narrow Screener checkpoint, with language metadata.
The catalog README now describes the already-implemented native shortcut recorder.

## Contract impact

`dreams.settings.host/native_controls`, `operation_semantics`, `one_settings_owner`,
`default_off` and `material_composition` retain their meanings. Hook rendering remains
inside SettingsPage.NativePresentation.Forms; no new boundary or HC role is needed.
The existing maps still bind the same paths. Only host source/evidence bindings change.
Renderer, overlay, hook installer, settings storage, catalog runtime, glyphs and tvOS
are unchanged; their prior evidence remains historical. Formal acceptance stays draft.

## Fresh verification

- [Release build](build.log) succeeds on the verified TB5 SSD. Swift 6.4 / arm64 macOS 27.
- `DREAMS_LANGUAGE=en` and `ru`, each with `make test-native-settings-trace`: exit 0,
  22 hierarchy frames each ([EN](trace-en.log), [RU](trace-ru.log)). All seven sections
  appear at 1000 and 560 point widths; additional recording, error, dark, paused,
  contrast and transparent states remain. The verifier checks section names and blobs.
- Narrow section screenshots in both languages were visually inspected. Final hook
  checkpoints confirm complete status text ([EN](hooks-en-narrow.png), [RU](hooks-ru-narrow.png)).
  Long Rain content extends below the narrow viewport; interactive narrow scrolling is
  still unverified, so these fixtures do not establish complete narrow input parity.
- Actual-app CUA visited all seven sections in EN/RU, checked sidebar arrows,
  shortcut recording → Esc and reset confirmation → Cancel. After containment,
  both hook buttons have separate AX IDs. See [observation and limits](actual-app.md).
  Hooks were never activated; no fullscreen, display selection or reset was performed.
- `make lint`: exit 0 ([log](lint.log)); the known unused_import SwiftLint warning remains.
  `python3 scripts/test-localization.py`: exit 0, 154 EN/RU keys and format specifiers match.
- HC/SpecPM structural validation and current source/snapshot hashes are recorded in
  [structure.log](structure.log) and [identities.log](identities.log). Structure is not
  visual or assistive-technology acceptance.

## Reproduction and limits

Use `DREAMS_LANGUAGE=en|ru DREAMS_TRACE_DIRECTORY=<external traces> make test-native-settings-trace`.
A temporary PATH wrapper preserves the Make target while passing SwiftPM
`--scratch-path <TB5 build>/swiftpm --cache-path /Volumes/TB5/Developer/Caches/swiftpm`.
Build identity: Dreams-36273a9c832f69b9; APFS UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36.
Python bytecode, ruff and Clang module outputs also use the verified SSD.
No bulk migration/deletion or internal-disk fallback was performed.

Screener SDK hierarchy snapshots establish layout states, not actual Metal/glass pixels.
Their black preview/selection and slider artifacts are capture limitations. The new
external traces were not discovered by Screener MCP's default session listing; PNGs
were inspected directly. [EN manifest](trace-en-manifest.json) and
[RU manifest](trace-ru-manifest.json) pin all 44 frame hashes and local trace locations.
Actual live rendering observations use CUA separately. Toolbar blur remains deliberately deferred.

Complete Tab traversal, VoiceOver, actual-app narrow interaction, macOS 15 and physical
multi-display behavior remain unverified. No full GPU suite, CI or release is claimed.
Next gate: complete keyboard/VoiceOver operation before enabling native settings by default.

Tool identities: SpecPM 0.2.0 at `/opt/homebrew/bin/specpm`; Hypercode at
`/Users/egor/Development/GitHub/0AL/Hypercode/.build/debug/hypercode`, executable SHA256
`6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
`make specs-check HYPERCODE=<above>` exits 0; existing unresolved external-capability
warnings remain descriptive draft dependencies, not proof of runtime conformance.
`python3 check-identities.py` checks current files and historical/current snapshot bytes.

All source snapshots were also compared byte-for-byte with `git show c7da63d:<path>`: pass.
