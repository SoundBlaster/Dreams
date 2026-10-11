#!/usr/bin/env python3
"""Check column settings against real Metal previews, without capturing the desktop."""
import base64
import io
import os
import tempfile

import numpy as np
from PIL import Image
from smoke import MCPClient

for requested, expected in [(0, 0), (24, 24), (80, 80), (240, 240), (999, 240), (1, 24)]:
    with tempfile.TemporaryDirectory(prefix="dreams-columns-") as feed:
        client = MCPClient(env=dict(os.environ, DREAMS_FEED_DIRECTORY=feed), publisher=True,
                           extra_args=["-rainColumnCount", str(requested), "-rainDensity", "1",
                                       "-rainIdleIntensity", "1", "-rainSpeed", "3", "-rainGlow", "0",
                                       "-transparentBackground", "NO"])
        try:
            client.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                          "clientInfo": {"name": "columns-check", "version": "1"}})
            client.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
            assert client.call("dreams_status")["rain_columns"] == expected
            result = client.request("tools/call", {"name": "dreams_preview", "arguments": {}})
            pixels = np.asarray(Image.open(io.BytesIO(base64.b64decode(result["content"][0]["data"]))).convert("RGB"))
            columns = expected or int(1512 / 982 * 72)
            occupied = pixels.max(axis=(0, 2)) > 8
            edges = np.diff(np.r_[False, occupied, False].astype(int))
            widths = np.flatnonzero(edges == -1) - np.flatnonzero(edges == 1)
            glyph_width = float(np.percentile(widths, 90))
            cell_width = pixels.shape[1] / columns
            assert 0.15 * cell_width <= glyph_width <= 1.3 * cell_width, (requested, glyph_width, cell_width)
            assert np.count_nonzero(pixels) > 1000
            print(f"PASS: setting {requested}, {columns} columns, glyph width {glyph_width:.1f}px / cell {cell_width:.1f}px")
        finally:
            client.close()
