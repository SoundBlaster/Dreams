"""Verify current slider-layout source/map and snapshot bytes."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
count = 0
for package in ["settings-host", "settings-catalog"]:
    base = root / "specs" / package
    identity = json.loads((base / "evidence/2026-10-18-alignment-review/source-identity.json").read_text())
    for item in identity["files"] + identity["maps"]:
        for path in [root / item["path"], base / item["snapshot"]]:
            assert hashlib.sha256(path.read_bytes()).hexdigest() == item["sha256"], path
        count += 1
print(f"PASS: {count} source/map and snapshot SHA256 pairs")
