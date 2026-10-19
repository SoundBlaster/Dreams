# Playback button actual-app QA

Actual isolated EN Dark700x600 app, QA-only sizing harness; stdout `QA_WINDOW_FRAME 700x600 scale=2.0`. No production app or preferences changed.

PASS: Live Preview title and full-width header panel absent. One trailing large green prominent glass button remains. Icon-only Pause→Play→Pause behavior confirmed by click and AX label, stable identifier `dreams.native.preview-playback`. Final state playing.

Playing and paused visible button bounds approximatelyx1184..1368,y32..112pixels (92x40pt) match in both captures; no button or surrounding layout jump. CUA AX does not expose native frame/bounds, so exact AX width unavailable; equality is screenshot-based. Paused stable screenshot captured before restoringPlay as additional freeze evidence; animated rain screenshots themselves are not treated as geometry failures.

Artifacts: playing.png, paused.png, paused-stable.png, playing-ax.txt, paused-ax.txt, resumed-ax.txt.

SourceWindow restored byte-for-byte: True. Normal binary restored byte-for-byte: True; SHA256 `184df8115784f5695a36e1297bf3c70ccbc7d2c2d51a6f82306f45521b8f75c6`. TB5 preflight and release helper build recorded; build.log retained.

Only Rain navigation and Pause/Play checked. No other cases.
