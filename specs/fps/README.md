# Optional FPS readout

[Contract](specs/readout.spec.yaml), [map](../hypercode/fps.hc),
[validation](validation/2026-10-24/README.md).

The native macOS Advanced and tvOS Advanced toggles default off. Digits come
from DreamsMatrix-Regular and are drawn in the existing Metal pass. The first
value appears after a full one-second sampling window. macOS observes drawable
presentation; tvOS observes completed GPU frames, as explained in its UI hint.
This is a diagnostic estimate, not a replacement for the performance protocol.

The owner clarified on 2026-10-24 that the count belongs inside the rain grid.
It now reserves three cells, using identical glyph quad size and grid spacing;
their rain cores/halos are skipped. The previous independent pixel-positioned
readout remains historical evidence only. [Current validation](validation/2026-10-24-grid/README.md).
