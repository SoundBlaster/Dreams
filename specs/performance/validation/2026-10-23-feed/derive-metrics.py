#!/usr/bin/env python3
"""Recompute the small additional table from archived raw reports."""
import gzip
import json
from pathlib import Path

root = Path(__file__).resolve().parent
summary = json.loads((root / "summary.json").read_text())
metrics = []
for row in summary["runs"]:
    events = row["events"]
    report = json.loads(gzip.decompress((root / "runs" / (row["file"] + ".gz")).read_bytes()))
    times = sorted(frame["presentedAt"] for frame in report["samples"] if "presentedAt" in frame)
    metrics.append({"run": row["file"], "snapshotP95ms": row["snapshotMs"]["p95"],
                    "snapshotMaximumMs": row["snapshotMs"]["max"],
                    "readLatencyP95ms": max(e["readLatencyMs"] for e in events),
                    "readToPresentedP95ms": max((e["firstPresentedLetter"] - e["firstRead"]) * 1000 for e in events),
                    "maximumScheduleLatenessMs": max(e["scheduleLatenessMs"] for e in events),
                    "presentationP99ms": row["presentationIntervalsMs"]["p99"],
                    "observedFPS": (len(times) - 1) / (times[-1] - times[0])})
print(json.dumps(metrics, indent=2))
assert metrics == json.loads((root / "derived-metrics.json").read_text())
