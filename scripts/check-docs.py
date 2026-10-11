#!/usr/bin/env python3
"""Check that every relative link in the Markdown files points to a file that exists."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
files = subprocess.run(["git", "ls-files", "*.md"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
broken = []
for name in files:
    path = ROOT / name
    for match in re.finditer(r"\]\(([^)\s#]+)(#[^)]*)?\)", path.read_text(encoding="utf8")):
        target = match.group(1)
        if re.match(r"[a-z]+:", target):  # http:, https:, mailto:
            continue
        if not (path.parent / target).exists():
            broken.append(f"{name}: {target}")
if broken:
    sys.exit("Broken relative links:\n  " + "\n  ".join(broken))
print(f"PASS: relative links in {len(files)} Markdown files")
