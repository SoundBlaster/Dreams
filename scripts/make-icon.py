#!/usr/bin/env python3
"""Build assets/AppIcon.icns from assets/icon/source.png (macOS Big Sur style tile).

  .venv/bin/python scripts/make-icon.py

The tile is 824 px on a 1024 canvas with a soft shadow, as in Apple's icon template. The result is
committed, so releases do not need Python.
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/icon/source.png"
OUTPUT = ROOT / "assets/AppIcon.icns"
CANVAS, TILE = 1024, 824
CROP = (140, 140, 1100, 1100)  # frames the glyph; the source is 1254 px with a lot of black around it


def squircle_mask(size, supersample=4, exponent=5.0):
    """A superellipse: the continuous-corner shape of macOS icons."""
    n = size * supersample
    axis = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(axis, axis)
    inside = (np.abs(x) ** exponent + np.abs(y) ** exponent) <= 1
    mask = Image.fromarray((inside * 255).astype(np.uint8), "L")
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def master():
    art = Image.open(SOURCE).convert("RGB").crop(CROP).resize((TILE, TILE), Image.Resampling.LANCZOS)
    mask = squircle_mask(TILE)
    tile = art.convert("RGBA")
    tile.putalpha(mask)
    # A faint rim keeps the dark tile readable on dark backgrounds.
    rim = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(5)))
    tile.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", (TILE, TILE), "white").split(), rim.point(lambda v: v * 0.10))))
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = ((CANVAS - TILE) // 2, (CANVAS - TILE) // 2)
    shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shadow_alpha = Image.new("L", (CANVAS, CANVAS), 0)
    shadow_alpha.paste(mask.point(lambda v: v * 0.55), (offset[0], offset[1] + 12))
    shadow.putalpha(shadow_alpha.filter(ImageFilter.GaussianBlur(14)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(tile, offset)
    return canvas


def main():
    icon = master()
    with tempfile.TemporaryDirectory() as tmp:
        iconset = Path(tmp) / "AppIcon.iconset"
        iconset.mkdir()
        for points in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                pixels = points * scale
                name = f"icon_{points}x{points}{'@2x' if scale == 2 else ''}.png"
                icon.resize((pixels, pixels), Image.Resampling.LANCZOS).save(iconset / name)
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(OUTPUT)], check=True)
        preview = ROOT / "assets/icon/preview-1024.png"
        icon.save(preview)
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size // 1024} KB) and assets/icon/preview-1024.png")


if __name__ == "__main__":
    main()
