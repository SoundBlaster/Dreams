# Slider alignment actual-app QA

Date: 2026-10-18 Europe/Moscow. Branch supplied by parent: codex/settings-slider-alignment. Read device-interaction skill; used CUA fallback because Xcode DeviceInteraction previously required approval/project setup. No builds or CI commands run.

Fresh isolated TB5 Dreams Parity EN.app and Dreams Parity RU.app inspected after parent ready signal. Both actual-app Appearance and Rain sections captured with screenshot plus AX (four fresh section screenshots), wide 2000x1600 pixels / approximately1000x800pt Retina2x.

PASS both languages: slider tracks share left/right edges visually around x846..1138 in screenshots, across sections Grid/Motion/Search and Appearance. Readout right edges align around x1316. These are visual estimates, not programmatic pixel measurements. Full labels such as Glyph brightness pulse and Пульсация яркости visible, no observed truncation or overlap. AX retains individual slider descriptions, values, readouts and stable IDs. Disabled automatic Columns and disabled deceleration controls reported as disabled as expected.

Interaction: isolated EN Glow AX Increment changed0.57/57% to0.58/58%; Decrement restored57% (AX Double0.5700000000000001). No other settings edited. Original apps, fullscreen and hooks untouched.

Screenshots emitted into CUA tool results; documented API has no direct filesystem screenshot export option. Actual-app narrow not checked; root owns separate Screener narrow/wide evidence. Keyboard traversal, VoiceOver announcements and exact pixel measurement not established by this bounded pass. UI released after RU Rain capture.
