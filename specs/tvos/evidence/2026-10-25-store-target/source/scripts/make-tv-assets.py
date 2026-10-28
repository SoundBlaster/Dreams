#!/usr/bin/env python3
"""Build the committed Apple TV icon layers and Top Shelf art from Dreams artwork.

Requires Pillow. No generated macOS tile, rounded corners or shadows are baked
into the TV assets; tvOS supplies the icon's mask and focus treatment.
"""

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "tvOS/Sources/shared/assets/Assets.xcassets"
BRAND = CATALOG / "App Icon & Top Shelf Image.brandassets"
INFO = {"author": "xcode", "version": 1}


def write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def image_set(path, sizes, artwork, foreground=False):
    images = []
    for scale, (width, height) in sizes.items():
        mode = "RGBA" if foreground else "RGB"
        background = (0, 0, 0, 0) if foreground else (0, 0, 0)
        canvas = Image.new(mode, (width, height), background)
        if artwork is not None:
            # Keep the mark inside the TV icon's safe area at every resolution.
            side = round(height * 0.78)
            mark = artwork.resize((side, side), Image.Resampling.LANCZOS)
            canvas.paste(mark, ((width - side) // 2, (height - side) // 2))
        filename = f"art@{scale}.png"
        path.mkdir(parents=True, exist_ok=True)
        canvas.save(path / filename, optimize=True)
        images.append({"filename": filename, "idiom": "tv", "scale": scale})
    write_json(path / "Contents.json", {"images": images, "info": INFO})


def icon_stack(name, sizes, artwork):
    path = BRAND / name
    layers = []
    for name, image in (("Front", artwork), ("Back", None)):
        layer = path / f"{name}.imagestacklayer"
        write_json(layer / "Contents.json", {"info": INFO})
        image_set(layer / "Content.imageset", sizes, image, foreground=name == "Front")
        layers.append({"filename": layer.name})
    write_json(path / "Contents.json", {"layers": layers, "info": INFO})


def main():
    # Match the macOS mark's framing, using the original unmasked artwork.
    artwork = Image.open(ROOT / "assets/icon/source.png").convert("RGB").crop((140, 140, 1100, 1100))
    write_json(CATALOG / "Contents.json", {"info": INFO})
    icon_stack("App Icon.imagestack", {"1x": (400, 240), "2x": (800, 480)}, artwork)
    icon_stack("App Icon - App Store.imagestack", {"1x": (1280, 768)}, artwork)
    image_set(BRAND / "Top Shelf Image.imageset", {"1x": (1920, 720), "2x": (3840, 1440)}, artwork)
    image_set(BRAND / "Top Shelf Image Wide.imageset", {"1x": (2320, 720), "2x": (4640, 1440)}, artwork)
    assets = [
        ("App Icon.imagestack", "primary-app-icon", "400x240"),
        ("App Icon - App Store.imagestack", "primary-app-icon", "1280x768"),
        ("Top Shelf Image.imageset", "top-shelf-image", "1920x720"),
        ("Top Shelf Image Wide.imageset", "top-shelf-image-wide", "2320x720"),
    ]
    write_json(BRAND / "Contents.json", {
        "assets": [{"filename": name, "idiom": "tv", "role": role, "size": size}
                   for name, role, size in assets],
        "info": INFO,
    })
    print(f"Wrote {CATALOG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
