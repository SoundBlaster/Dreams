# Content icons actual-app QA

EN normal1000x720: Rain, Appearance and Displays screenshots/AX. RU and EN compact700x600 Rain using temporary QA-only sizing harness; RU stdout `QA_WINDOW_FRAME 700x600 scale=2.0` (exec13048). Fresh isolated domains, green60%, Dark. No production app/preferences/system changes.

PASS: content icons visible, monochrome secondary, consistently aligned. Rain slider tracks/readouts keep common edges. Appearance long Glyph brightness pulse wraps to2lines without overlap and its slider/readout remain aligned. Displays labels/picker/switch readable; no physical display settings changed.

Compact EN Rain top and bottom scrolled screenshots confirm Decelerate drops, acceleration, Searching glyphs and full help paragraph readable. RU700 top screenshot confirms Cyrillic labels,7sidebarrows and icon/title/slider/readout alignment; lower RU controls were present in AX but not visually scrolled in the requested single RU capture.

AX controls preserve localized descriptions and stable IDs (e.g. dreams.rain-density, dreams.rain-speed, dreams.rain-search-fraction, dreams.rain-color, dreams.display-mode). Decorative content icons do not introduce image accessibility nodes; only the existing Live Preview image is exposed. General was inspected in AX at launch; no dedicated General screenshot. Agent words/hook rows were not retested.

Artifacts: rain-wide.png, appearance-wide.png, displays-wide.png, rain-700.png, rain-700-bottom.png, rain-700-ru.png, matching AX text.

TB5 preflight succeeded; release sizing harness build log retained. Temporary Window source restored byte-for-byte=True; normal binary restored byte-for-byte=True. No other source modified by QA.
