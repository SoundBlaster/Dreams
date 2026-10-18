# Actual preview growth QA

Isolated Dreams Preview QA.app, EN Dark, new release binary supplied by parent.

Native AX secondary action `zoom the window` succeeded without fullscreen. Baseline PNG 2000x1600 px (1000x800 pt), Zoom PNG 2928x1898 px (1464x949 pt).

At Retina2x, settings foundation visually remains x474..1434 in both captures, i.e.480pt wide. Preview outline starts around x1466 and grows from right edge1968 to2896, approximately251pt to715pt wide. These coordinates are visual screenshot estimates, not runtime NSView frame measurements. All setting labels/values remain in the same positions, header and helpers readable. Extra horizontal width visibly goes to preview, glyphs render across the enlarged area at unchanged apparent glyph size.

AX Rain values remained Automatic on,110 columns,0% density,.43 speed,3glyph fade,-12 disabled deceleration,10% search. No settings or fullscreen overlay were changed. App left open on Rain in native Zoom state.

Artifacts:
- /tmp/dreams-preview-growth-qa/baseline.png
- /tmp/dreams-preview-growth-qa/baseline-ax.txt
- /tmp/dreams-preview-growth-qa/zoom.png
- /tmp/dreams-preview-growth-qa/zoom-ax.txt
