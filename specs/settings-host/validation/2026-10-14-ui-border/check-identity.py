#!/usr/bin/env python3
"""Verify host inputs and reject semantic UI changes against the pinned baseline."""
import hashlib
import json
from pathlib import Path
import tempfile

HOST = Path(__file__).resolve().parents[2]
ROOT = HOST.parents[1]
DATE = Path(__file__).parent.name


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    identity = json.loads((HOST / "evidence" / DATE / "source-identity.json").read_text())
    for category in ["files", "maps"]:
        for item in identity[category]:
            assert digest(ROOT / item["path"]) == item["sha256"], item["path"]
            assert digest(HOST / item["snapshot"]) == item["sha256"], item["snapshot"]
    mutations = [
        ("Packages/DreamsSettingsUI/Package.swift", ".macOS(.v15)", ".macOS(.v26)"),
        ("Packages/DreamsSettingsUI/Sources/DreamsSettingsUI/SettingsSliderRow.swift",
         "Slider(value: $value, in: range, step: step)", "Slider(value: $value, in: 0...1, step: step)"),
    ]
    for name, old, new in mutations:
        item = next(item for item in identity["files"] if item["path"] == name)
        original = (ROOT / name).read_bytes()
        assert old in original.decode()
        with tempfile.TemporaryDirectory(prefix="dreams-ui-border-") as temp:
            candidate = Path(temp) / Path(name).name
            candidate.write_bytes(original)
            assert digest(candidate) == item["sha256"]
            candidate.write_text(original.decode().replace(old, new, 1))
            assert digest(candidate) != item["sha256"], name
        assert (ROOT / name).read_bytes() == original
    print("PASS: current host/source snapshots match; both semantic UI mutations rejected")


if __name__ == "__main__":
    main()
