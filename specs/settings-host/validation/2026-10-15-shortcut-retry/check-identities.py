"""Verify current source, map and evidence bytes for the shortcut integration."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[4]
count = 0
for package in ["settings-host", "overlay-session", "drop-motion"]:
    base = root / "specs" / package
    identity = json.loads((base / "evidence/2026-10-15-shortcut-retry/source-identity.json").read_text())
    for item in identity["files"] + identity["maps"]:
        expected = item["sha256"]
        for path in [root / item["path"], base / item["snapshot"]]:
            assert hashlib.sha256(path.read_bytes()).hexdigest() == expected, path
        count += 1
print(f"PASS: {count} source/map and snapshot SHA256 pairs")
