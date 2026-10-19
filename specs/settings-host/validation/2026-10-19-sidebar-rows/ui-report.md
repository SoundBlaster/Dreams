# Combined sidebar / preview position actual-app QA

Fresh isolated EN Dark app, parent final combined build READY 2026-10-19 06:48 UTC. App binary SHA256 `ab29d618e170a6d927aa4516a462a00705b3eeaf4ddc23cff4a50e031cf739dc`; equal to current release product: `False`. Fresh resource bundle and actual icon copied. No build/source edits.

## Preview position: PASS
- Appearance screenshot: `appearance.png`; Rain screenshot: `rain.png`. Same 2000x1440 screenshot window.
- In both captures, Live Preview header is approximately x1464..1967, y32..121 pixels. Footer is approximately x1464..1967, y1283..1407. These are visual estimates, not AX frame measurements.
- Rain tab no longer shifts preview card/header downward or changes its width. Rain-only outline remains around preview; header/footer align with Appearance. Changing rain glyphs between captures is animation, not a geometry defect.
- AX confirms Appearance selected with Color/Glyphs form, then Rain selected with Grid/Motion/Searching glyphs form. No fullscreen action or preference change.

## Sidebar rows
- All seven rows visible, labels and icons align, no clipping. Rows visibly more spacious than previous candidate (about44pt centers versus about33pt previously).
- Appearance green palette icon and native neutral selection correctly move to Rain green sliders icon; inactive icons are visually gray, not pure white, despite the requested primary tint. Inactive labels remain white/readable. This is reported as observed, not inferred implementation behavior.

Bounded two-tab pass only. No themes, narrow window, keyboard, production settings, hooks or overlay retesting. App left on Rain.
