# Visible rounded material panels — 2026-10-18

Runtime `25e7aaa0bd9e32418294c4fa54720e06fcc39ac4` removes the Rain-only rectangular background branch and uses the
existing SettingsMaterialPanel for every section. The shared component draws and
clips a 16pt rounded rectangle, matching the preview outline radius. This restores
visible outer corners and inherits its opaque accessibility fallback without a
second implementation. The 480pt form cap and flexible preview allocation are unchanged.

Host material_composition is updated in draft.8; HC Forms composition reflects the
shared panel. Stable native_controls, independent_preview, preview_scale, default_off
and one_settings_owner claims retain their requirements. Catalog/library and renderer
sources are unchanged, with previous acceptance state retained. Source and map hashes
are pinned in [current identity](../../evidence/2026-10-18-panel-corners/source-identity.json).

Fresh actual-app [screenshot](actual-dark.png) and [operator report](actual-app-report.md):
outer corners visibly round (about32px at2x), no square spill, text/readouts readable,
form width still about480pt. The app remains on Rain, no preferences changed.

Fresh checks: [release build](build.log), [lint](lint.log), [structure](structure.log)
and [identity hashes](identities.log). Previous 58 fixture frames and Zoom observations
remain on their original revision in [width allocation](../2026-10-18-preview-growth/README.md).
This small appearance fix adds no redundant implementation-mirroring tests.

TB5 UUID04B9F65E-894C-4A7C-B517-FC542E8D8E36; checkout Dreams-36273a9c832f69b9.
No preferences, glyph files, renderer algorithms, CI watch or release changes.
Formal acceptance, keyboard/VoiceOver and macOS15 physical runtime remain separate.
