#!/usr/bin/env python3
"""Describe refresh cost and event-to-presented-letter proxy; never claim pixel acceptance."""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import uuid

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("performance_reports", ROOT / "scripts/summarize-performance.py")
reports = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reports)


def metric(values):
    if any(not math.isfinite(v) or v < 0 for v in values):
        raise ValueError("Missing, negative or nonfinite duration")
    ordered = sorted(values)
    return {"count": len(values)} | {name: ordered[max(0, math.ceil(len(ordered) * rank) - 1)] if ordered else None
                                   for name, rank in [("p50", .5), ("p95", .95), ("p99", .99), ("max", 1)]}


def analyze_run(report, publication, trace):
    if report.get("schemaVersion") != 3 or report.get("feedProbe") is not True or report.get("calibration") is not None:
        raise ValueError("A full feed probe is required")
    samples = report["samples"]
    refreshes = [(s, s["feedRefresh"]) for s in samples if s.get("feedRefresh") is not None]
    events = []
    for index, event in enumerate(trace["events"]):
        identity = str(uuid.uuid5(uuid.NAMESPACE_URL, f"dreams-feed/{trace['name']}/{index}"))
        writes = [w for w in publication["writes"] if w["eventID"] == identity]
        if len(writes) != 1:
            raise ValueError("Expected exactly one publication per event")
        write = writes[0]
        read = [r["ended"] for _, r in refreshes if r["succeeded"] and identity in [i.lower() for i in r["eventIDs"]]]
        shown = [s["presentedAt"] for s in samples if identity in [i.lower() for i in s.get("eventLetters", [])]
                 and s.get("presentedAt", 0) > 0 and s.get("gpuCompleted") and not s.get("gpuFailed")]
        first_read, first_shown = min(read, default=None), min(shown, default=None)
        valid = (first_read is not None and first_shown is not None
                 and write["commitBegan"] <= write["committed"] <= first_read <= first_shown)
        events.append({"id": identity, "label": event["label"], "valid": valid,
                       "publicationBegin": write["commitBegan"], "publicationEnd": write["committed"],
                       "scheduleLatenessMs": (write["commitBegan"] - write["scheduled"]) * 1000,
                       "firstRead": first_read, "firstPresentedLetter": first_shown,
                       "readLatencyMs": (first_read - write["committed"]) * 1000 if valid else None,
                       "presentationLatencyLowerMs": (first_shown - write["committed"]) * 1000 if valid else None,
                       "presentationLatencyUpperMs": (first_shown - write["commitBegan"]) * 1000 if valid else None})
    valid = (report["valid"] and publication["exitCode"] == 0 and bool(refreshes) and all(e["valid"] for e in events)
             and publication["remainingJSONFiles"] == trace["sessions"]
             and all(r["messageCount"] == trace["sessions"] for _, r in refreshes if r["succeeded"]))
    durations = [(r["ended"] - r["began"]) * 1000 for _, r in refreshes]
    return {"valid": valid, "refreshes": len(refreshes), "failedRefreshes": sum(not r["succeeded"] for _, r in refreshes),
            "mainThreadRefreshes": sum(r["onMainThread"] for _, r in refreshes),
            "snapshotMs": metric(durations), "refreshDrawMs": metric([s["drawSeconds"] * 1000 for s, _ in refreshes]),
            "otherDrawMs": metric([s["drawSeconds"] * 1000 for s in samples if s.get("feedRefresh") is None]),
            "presentationIntervalsMs": {k: v * 1000 if v is not None and k != "count" else v
                                        for k, v in report["summaries"]["presentation_interval_seconds"].items()},
            "intervalsOver50ms": report["intervalsOver50ms"], "intervalsOver100ms": report["intervalsOver100ms"],
            "glyphRasterizations": sum(s["glyphRasterizations"] for s in samples),
            "eventLatencyMs": metric([e["presentationLatencyUpperMs"] for e in events if e["valid"]]), "events": events}


def analyze(directory):
    manifest = json.loads((directory / "manifest.json").read_text())
    for path, key in [("scenario.json", "fixtureSHA256"), ("trace.json", "traceSHA256")]:
        if hashlib.sha256((directory / path).read_bytes()).hexdigest() != manifest[key]:
            raise ValueError("Fixture identity mismatch")
    trace = json.loads((directory / "trace.json").read_text())
    runs = []
    identity = None
    for result in manifest["results"]:
        report = reports.read_report(directory / result["file"])
        if report["fixtureSHA256"] != manifest["fixtureSHA256"] or report["revision"] != manifest["revision"]:
            raise ValueError("Report/manifest identity mismatch")
        current = {k: report[k] for k in ["device", "os", "cpu", "backingScale", "screenMaximumFPS", "screenFrame"]}
        if identity is not None and current != identity:
            raise ValueError("Mixed run hardware/display identities")
        identity = current
        publication = json.loads((directory / result["publication"]).read_text())
        value = analyze_run(report, publication, trace)
        value["valid"] = value["valid"] and result["valid"] and result["exitCode"] == 0
        runs.append(value | {"file": result["file"], "thermalStates": report["thermalStates"]})
    return {"schemaVersion": 1, "runKind": manifest["runKind"], "revision": manifest["revision"],
            "binarySHA256": manifest["binarySHA256"], "fixtureSHA256": manifest["fixtureSHA256"],
            "traceSHA256": manifest["traceSHA256"], "identity": identity,
            "allValid": bool(runs) and all(r["valid"] for r in runs), "runs": runs,
            "limits": "Snapshot API wall time, not syscall counts. First presented drawable with a stable non-space event letter is a proxy, not pixel/OCR or full-label acceptance. Single renderer, warm filesystem cache, no tvOS/fullscreen or causal speedup claim."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    result = analyze(args.directory)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if not result["allValid"]:
        raise SystemExit(1)
