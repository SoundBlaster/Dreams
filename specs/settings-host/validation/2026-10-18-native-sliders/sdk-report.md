# Actual SDK metadata glass A/B

Parent supplied same source relinked with LC_BUILD_VERSION minos15 SDK27, fresh isolated Dreams SDK QA.app. EN Dark actual app via CUA. Compared with prior /tmp/dreams-smooth-sliders-qa/rain.png (SDK15 metadata, parent observation).

Strong visible style change: modern native slider thumbs are horizontal pills (~40x32px), tracks thicker, switches elongated. Fade sparse scale now dots below track; dense tracks remain smooth. Sidebar typography/icons/selection, toolbar/background glass, form group rendering and helper alignment changed. AX sliders changed from secondary Increment/Decrement with nested indicators to settable float sliders.

NEW ACTUAL VISUAL DEFECT: full-width blur material below toolbar (~y104..208 screenshotpixels) overlays detail content. Rain heading is visually hidden and Live Preview top/header text partially covered. Both remain in AX. Captured again without interaction; band persists. This is actual app, not Screener/SwiftPM fixture. Do not continue claiming fixture-only on SDK27 linked binary.

Artifacts:
- /tmp/dreams-sdk-glass-qa/rain.png
- /tmp/dreams-sdk-glass-qa/rain-stable.png
- /tmp/dreams-sdk-glass-qa/rain-ax.txt

No settings changed, no fullscreen. App left open on Rain. Pressed-state Liquid Glass not captured: CUA only documents drag without hold-and-capture API; resting-shape A/B already decisive.
