#!/usr/bin/env python3
"""Set the release version everywhere it is kept: VERSION and the two plugin manifests.

  scripts/bump-version.py 0.1.3
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv) != 2 or not re.fullmatch(r"\d+\.\d+\.\d+", sys.argv[1]):
    sys.exit("usage: scripts/bump-version.py MAJOR.MINOR.PATCH")
version = sys.argv[1]
(ROOT / "VERSION").write_text(version + "\n")
for manifest in (ROOT / "plugins/dreams-claude/.claude-plugin/plugin.json", ROOT / "plugins/dreams-codex/plugin.json"):
    data = json.loads(manifest.read_text(encoding="utf8"))
    data["version"] = version
    manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
print(f"Version {version}: VERSION and both plugin manifests updated. Commit, then make release.")
