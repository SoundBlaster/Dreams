#!/usr/bin/env python3
"""Inspect native PNGs; requires Pillow/numpy (existing Dreams .venv)."""
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw


def pixels(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)


def main():
    directory = Path(sys.argv[1]).resolve()
    report = {}
    for run in sorted(directory.iterdir()):
        if not (run / "manifest.json").is_file():
            continue
        manifest = json.loads((run / "manifest.json").read_text())
        scale = manifest["scale"]
        roi = (slice(int(60 * scale), int(420 * scale)), slice(int(20 * scale), int(620 * scale)))
        rows = []
        previous = None
        for row in manifest["rows"]:
            name = row["name"]
            appkit = pixels(run / f"{name}-appkit.png")
            measured = dict(row)
            measured["appkitMetalROIVariance"] = float(appkit[roi].var(axis=(0, 1)).sum())
            if (run / f"{name}-system.png").is_file() and (run / f"{name}-sck.png").is_file():
                system = pixels(run / f"{name}-system.png")
                sck = pixels(run / f"{name}-sck.png")
                if system.shape != sck.shape or system.shape != appkit.shape:
                    raise RuntimeError(f"Unmatched native geometry: {run}/{name}")
                difference = np.abs(system - sck)
                measured.update(sckVsSystemMAE=float(difference.mean()),
                                sckVsSystemMax=int(difference.max()),
                                sckVsSystemExactPixelFraction=float(np.all(system == sck, axis=2).mean()),
                                appkitVsSystemMAE=float(np.abs(system - appkit).mean()),
                                systemMetalROIVariance=float(system[roi].var(axis=(0, 1)).sum()))
                if previous is not None:
                    measured["metalChangedSincePreviousFraction"] = float(np.any(previous != system[roi], axis=2).mean())
                previous = system[roi]
            rows.append(measured)
        report[run.name] = {"scale": scale, "permission": manifest["screenRecordingPermission"], "rows": rows}
    report["sourcePNGSHA256"] = {str(p.relative_to(directory)): hashlib.sha256(p.read_bytes()).hexdigest()
                                for p in sorted(directory.glob("*/*.png"))}
    first = directory / "transparent-1"
    second = directory / "transparent-2"
    if (first / "01-fixed-system.png").exists() and (second / "01-fixed-system.png").exists():
        a, b = pixels(first / "01-fixed-system.png"), pixels(second / "01-fixed-system.png")
        report["repeatFixedMAE"] = float(np.abs(a - b).mean())
    (directory / "analysis.json").write_text(json.dumps(report, indent=2) + "\n")
    canvas = Image.new("RGB", (1280, 940), "white")
    for y, mode in enumerate(["transparent-1", "opaque"]):
        for x, backend in enumerate(["appkit", "sck"]):
            source = directory / mode / f"01-fixed-{backend}.png"
            if not source.exists():
                continue
            image = Image.open(source).convert("RGB")
            image.thumbnail((640, 440))
            canvas.paste(image, (640 * x, 470 * y + 30))
            ImageDraw.Draw(canvas).text((640 * x + 12, 470 * y + 10), f"{mode}: {backend}", fill="black")
    canvas.save(directory / "comparison.png")
    for name, entry in report.items():
        if not isinstance(entry, dict) or "rows" not in entry:
            continue
        print(name, "frames:", len(entry["rows"]),
              "max SCK/system MAE:", max(r.get("sckVsSystemMAE", -1) for r in entry["rows"]),
              "AppKit Metal variance:", max(r["appkitMetalROIVariance"] for r in entry["rows"]))
    print("repeatFixedMAE:", report.get("repeatFixedMAE"))


if __name__ == "__main__":
    main()
