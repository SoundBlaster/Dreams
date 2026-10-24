# Centered settings and Play/Pause verification

- Runtime supplied by parent: 71e0977ed439bae7d7f316186e0c4f032dc71452. Debug Apple TV4K1080p tvOS27 Simulator B29EC156-5EF9-4A56-8147-1C98D4E228DB. App PID58786.
- Six capture calls. Initial capture contained transient HeadBoard/launch UI; next capture showed running settings correctly.
- Play/Pause opened menu from rain. Screenshot shows centered rounded panel and interior gutters; AX Table x434,y144,width1052,height792 on1920x1080, midpoint(960,540). Parent implementation says outer1100x840, inner24padding: observed bounds agree. Corners visibly rounded; exact radius not inferred from pixels.
- Automatic columns Focused natively on open. Down selects Columns64; Right changes65; Left restores64 as verified in reopened capture.
- Play/Pause while menu open closes it; return screenshot has no Table and Matrix rain Focused.
- Select reopens menu, restores Automatic columns focus, Columns64. No visible clipping/overlap on tested viewport.
- Native Live preview toggle remains present; no new matrix/locale/VoiceOver/performance checks performed.
- Final settings open. Session ended via tool; simulator released. No source/build changes by verifier.
