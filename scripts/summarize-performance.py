#!/usr/bin/env python3
"""Summarize each run without pooling percentiles or hiding invalid measurements."""
import argparse
import json
from pathlib import Path
import statistics


def summarize(directory):
    manifest = json.loads((directory / "manifest.json").read_text())
    runs = []
    for result in manifest["results"]:
        report = json.loads((directory / result["file"]).read_text())
        samples = report["samples"]
        intervals = report["summaries"]["presentation_interval_seconds"]
        times = sorted(s["presentedAt"] for s in samples if "presentedAt" in s)
        elapsed = times[-1] - times[0] if len(times) > 1 else 0
        runs.append({
            "file": result["file"], "valid": report["valid"] and result["exitCode"] == 0,
            "frames": len(samples), "observedFPS": intervals["count"] / elapsed if elapsed > 0 else None,
            "drawP95ms": report["summaries"]["draw_seconds"].get("p95", 0) * 1000,
            "simulationP95ms": report["summaries"]["simulation_seconds"].get("p95", 0) * 1000,
            "instancesP95ms": report["summaries"]["instances_seconds"].get("p95", 0) * 1000,
            "gpuP95ms": None if not report["summaries"]["gpu_seconds"]["count"] else report["summaries"]["gpu_seconds"]["p95"] * 1000,
            "presentationP99ms": None if not intervals["count"] else intervals["p99"] * 1000,
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
