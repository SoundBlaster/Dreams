# Actual-app native settings parity QA

Date: 2026-10-16 Europe/Moscow. CUA native UI, device-interaction skill.

## Scope and environment

Actual isolated apps on TB5: parity/Dreams Parity EN.app and parity/Dreams Parity RU.app; bundle IDs ru.egormerkushev.dreams.parity-en and ru.egormerkushev.dreams.parity-ru. Root supplied main 4d50110 binaries, then rebuilt NativeHookRow accessibility containment fix. Aqua appearance, observed screenshots 2000 x 1600 pixels (approximately 1000 x 800 points at 2x).

## Checks completed

- Both EN and RU: visited every actual app section, each with screenshot and AX observation: General/Основные, Appearance/Внешний вид, Rain/Дождь, Background/Фон, Agent words/Слова агентов, Displays/Экраны, Advanced/Дополнительно.
- All wide section labels, parameter values, descriptive text and controls readable; no observed overlap or truncation. Shared Metal rain and pale heads visible.
- Sidebar Down changed General to Appearance in each language.
- Both languages: began shortcut recording and cancelled with Esc; settings window remained open and shortcut stayed Ctrl+Option+Command+D.
- Both languages: opened Reset confirmation, verified localized Cancel/Reset buttons, clicked Cancel. No reset applied.
- Both languages: Rain final Searching glyphs/Перебор slider and complete help text visible. One downward scroll on Rain did not change AX state because all content fit the wide form.
- Hook Update buttons were initially visible in screenshots but absent from AX. After root accessibility containment fix, both languages expose distinct button IDs dreams.hooks-codex and dreams.hooks-claude, with Update/Обновить labels. Buttons were not activated.

## Precise limitations

- Keyboard control traversal is NOT established. EN Tab x4 from sidebar and RU Option+Tab x3 did not show an observable focused control transition in AX. System Keyboard navigation preferences were not modified. Sidebar arrows are verified, complete keyboard access to buttons/sliders is not.
- Actual-app narrow resize is NOT verified. CUA has no documented window-size setter, and an earlier bounded edge-drag attempt in this session did not change window bounds. Root runs separate Screener wide/narrow fixtures; their evidence is separate from actual-app observations.
- Screenshots were emitted by CUA getAXStateAndScreenshot into tool results. Its documented API returns image bytes, without a filesystem export/path option; no screenshot disk path is claimed. Root Screener trace supplies saved screenshot artifacts.
- VoiceOver announcement order and physical display routing not tested. System toolbar blur intentionally excluded.

No production app or previous verification app was touched. No fullscreen, hook installation, physical display selection or reset was performed. Isolated preferences were not changed.

## Exact-source final recheck

Root supplied rebuilt isolated bundles from c7da63dbc30ced3712ea9e5d357be6737791128a (NativeHookRow children containment and multiline status fixedSize). EN Agent words actual-app recheck: both dreams.hooks-codex and dreams.hooks-claude AX buttons present; full Needs an update labels and buttons visually readable in wide screenshot, without clipping. No hook activated.

Final RU recheck initially blocked: app observed at Основные, sidebar click twice and AX Raise did not change selection; screenshot appeared inactive. Earlier containment-only RU recheck passed, but that is not evidence for this final source. Root informed to check focus/fixture interference.

EN close button was attempted, but subsequent AX returned a settings window (possibly reopened by observation/app activation); cleanup not confirmed at this point. Production app remains untouched.

Final RU retry after root stopped isolated EN process succeeded: actual RU Agent words at exact source c7da63dbc30ced3712ea9e5d357be6737791128a exposes both dreams.hooks-codex and dreams.hooks-claude buttons, with full Нужно обновить statuses and readable Обновить buttons. Wide screenshot has no observed clipping. The temporary activation issue is resolved and does not block final exact-source RU recheck. No hook action activated. Root owns cleanup of remaining exact-path RU test process; no further CUA cleanup attempted.

Root then terminated the remaining isolated RU process by exact executable path. Both isolated test processes are stopped.
