#!/usr/bin/env python3
"""Summarize each run without pooling percentiles or hiding invalid measurements."""
import argparse
import gzip
import json
from pathlib import Path
import statistics


def read_report(path):
    if path.exists():
        return json.loads(path.read_text())
    return json.loads(gzip.decompress(Path(str(path) + ".gz").read_bytes()))


def milliseconds(summary, percentile):
    value = summary.get(percentile)
    return None if value is None else value * 1000


def summarize(directory):
    manifest = json.loads((directory / "manifest.json").read_text())
    runs = []
    for result in manifest["results"]:
        report = read_report(directory / result["file"])
        if report.get("feedProbe"):
            raise ValueError("Feed reports require scripts/analyze-feed-performance.py; include event delivery checks.")
        if report.get("calibration") is not None:
            raise ValueError("Calibration reports require scripts/analyze-calibration.py; control has no full-collector samples.")
        samples = report["samples"]
        intervals = report["summaries"]["presentation_interval_seconds"]
        times = sorted(s["presentedAt"] for s in samples if "presentedAt" in s)
        elapsed = times[-1] - times[0] if len(times) > 1 else 0
        runs.append({
            "file": result["file"], "valid": report["valid"] and result["exitCode"] == 0,
            "frames": len(samples), "observedFPS": intervals["count"] / elapsed if elapsed > 0 else None,
            "drawP95ms": milliseconds(report["summaries"]["draw_seconds"], "p95"),
            "simulationP95ms": milliseconds(report["summaries"]["simulation_seconds"], "p95"),
            "instancesP95ms": milliseconds(report["summaries"]["instances_seconds"], "p95"),
            "gpuP95ms": milliseconds(report["summaries"]["gpu_seconds"], "p95"),
            "presentationP99ms": milliseconds(intervals, "p99"),
            "intervalsOver50ms": report["intervalsOver50ms"], "intervalsOver100ms": report["intervalsOver100ms"],
            "meanCoreInstances": statistics.mean(s["coreInstances"] for s in samples) if samples else None,
            "meanHaloInstances": statistics.mean(s["haloInstances"] for s in samples) if samples else None,
            "bufferCreations": sum(s["bufferCreations"] for s in samples),
            "bufferBytes": sum(s["bufferBytes"] for s in samples),
            "glyphRasterizations": sum(s["glyphRasterizations"] for s in samples),
        })
    return {"schemaVersion": 1, "scenario": json.loads((directory / "scenario.json").read_text()),
            "runKind": manifest["runKind"], "revision": manifest["revision"],
            "binarySHA256": manifest["binarySHA256"], "fixtureSHA256": manifest["fixtureSHA256"],
            "allValid": bool(runs) and all(r["valid"] for r in runs), "runs": runs,
            "limits": "Windowed single-renderer probe; no allocation, energy, fullscreen, tvOS or per-pass GPU acceptance."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    print(json.dumps(summarize(args.directory), indent=2))


if __name__ == "__main__":
    main()
