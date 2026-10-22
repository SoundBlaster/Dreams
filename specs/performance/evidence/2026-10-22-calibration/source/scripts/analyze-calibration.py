#!/usr/bin/env python3
"""Compare full collector to bracketing controls; preserve spread and negative deltas."""
import argparse
import gzip
import hashlib
import json
import math
from pathlib import Path
import statistics


def read_json(path):
    data = path.read_bytes() if path.exists() else gzip.decompress(Path(str(path) + ".gz").read_bytes())
    return json.loads(data)


def describe(values):
    values = [value for value in values if value is not None]
    return None if not values else {"median": statistics.median(values), "minimum": min(values), "maximum": max(values)}


def analyze(root):
    suite = read_json(root / "suite.json")
    if suite["order"] != ["control", "full", "control"]:
        raise ValueError("Expected fixed control/full/control blocks")
    identities, rows, positions = set(), [], set()
    for entry in suite["runs"]:
        key = (entry["block"], entry["position"])
        if (entry["position"] not in (1, 2, 3) or not 1 <= entry["block"] <= suite["blocks"]
                or key in positions or entry["mode"] != suite["order"][entry["position"] - 1]):
            raise ValueError("Duplicate or mismatched block position")
        positions.add(key)
        folder = root / entry["directory"]
        manifest, report = read_json(folder / "manifest.json"), read_json(folder / "run-01.json")
        fixture_hash = hashlib.sha256((folder / "scenario.json").read_bytes()).hexdigest()
        if fixture_hash != manifest["fixtureSHA256"] or fixture_hash != report["fixtureSHA256"]:
            raise ValueError("Fixture digest mismatch")
        if report["revision"] != manifest["revision"] or report["schemaVersion"] != 2:
            raise ValueError("Report source or schema mismatch")
        mode = entry["mode"]
        cal = report["calibration"]
        if cal["mode"] != mode or manifest["calibrationMode"] != mode or manifest["runKind"] != suite["runKind"]:
            raise ValueError("Calibration mode/run kind mismatch")
        identities.add((manifest["revision"], manifest["binarySHA256"], fixture_hash,
                        json.dumps(manifest["resourceSHA256"], sort_keys=True), report["device"], report["os"],
                        report["backingScale"], report["screenMaximumFPS"], report["screenFrame"]))
        frames = len(cal["samples"])
        collector_matches = len(report["samples"]) == (0 if mode == "control" else frames)
        cpu = cal.get("cpu")
        cpu_seconds = None if cpu is None else cpu["userSeconds"] + cpu["systemSeconds"]
        times = sorted(sample["presentedAt"] for sample in cal["samples"]
                       if sample.get("presentedAt") is not None and sample["presentedAt"] > 0)
        per_draw = None if cpu_seconds is None or not frames else cpu_seconds / frames
        finite_cpu = per_draw is not None and math.isfinite(per_draw) and per_draw >= 0
        recorded = cal.get("processCPUSecondsPerDraw")
        if finite_cpu and (recorded is None or not math.isclose(recorded, per_draw, rel_tol=1e-9, abs_tol=1e-12)):
            raise ValueError("Process CPU normalization mismatch")
        valid = (entry["exitCode"] == 0 and report["valid"] and manifest["results"][0]["valid"]
                 and manifest["results"][0]["exitCode"] == 0 and collector_matches and finite_cpu
                 and frames == cal["draw"]["count"] and len(times) >= 2 and cal["pendingCallbacks"] == 0 and cal["overflow"] == 0)
        rows.append({"block": entry["block"], "position": entry["position"], "mode": mode, "directory": entry["directory"],
                     "valid": valid, "draws": frames, "processCPUmsPerDraw": None if per_draw is None else per_draw * 1000,
                     "processCPUSeconds": cpu_seconds, "processCPUCores": None if cpu_seconds is None else cpu_seconds / report["measuredSeconds"],
                     "outerDrawP50ms": None if cal["draw"].get("p50") is None else cal["draw"]["p50"] * 1000,
                     "outerDrawP95ms": None if cal["draw"].get("p95") is None else cal["draw"]["p95"] * 1000,
                     "presentationP99ms": None if cal["presentation"].get("p99") is None else cal["presentation"]["p99"] * 1000,
                     "observedFPS": (len(times) - 1) / (times[-1] - times[0]) if len(times) > 1 and times[-1] > times[0] else None,
                     "over50ms": cal["intervalsOver50ms"], "over100ms": cal["intervalsOver100ms"],
                     "unpresentedSamples": cal["unpresentedSamples"], "unavailableDrawable": cal["unavailableDrawable"],
                     "thermalStates": report["thermalStates"]})
    if len(identities) != 1:
        raise ValueError("Mixed source/binary/fixture/device identities cannot calibrate one collector")
    blocks = []
    for block in range(1, suite["blocks"] + 1):
        selected = sorted((row for row in rows if row["block"] == block), key=lambda row: row["position"])
        if len(selected) != 3 or not all(row["valid"] for row in selected):
            continue
        before, full, after = selected
        data = {"block": block}
        for metric in ["processCPUmsPerDraw", "outerDrawP50ms", "outerDrawP95ms", "presentationP99ms", "observedFPS"]:
            if any(row[metric] is None for row in selected):
                data[metric] = None
                continue
            reference = (before[metric] + after[metric]) / 2
            data[metric] = {"controlBracketMean": reference, "full": full[metric], "delta": full[metric] - reference,
                            "controlToControlDelta": after[metric] - before[metric]}
        blocks.append(data)
    complete = len(rows) == suite["blocks"] * 3 and len(blocks) == suite["blocks"] and all(row["valid"] for row in rows)
    nominal = all(row["thermalStates"] == [0] for row in rows)
    deltas = [block["processCPUmsPerDraw"]["delta"] for block in blocks]
    control_spread = [abs(block["processCPUmsPerDraw"]["controlToControlDelta"]) for block in blocks]
    sufficient = suite["runKind"] == "calibration" and len(blocks) >= 5
    resolved = bool(complete and nominal and sufficient and min(deltas) > max(control_spread))
    return {"schemaVersion": 1, "runKind": suite["runKind"], "complete": complete, "sufficientRepeats": sufficient,
            "nominalThermalStates": nominal, "identities": [list(identity) for identity in sorted(identities)],
            "runs": rows, "blocks": blocks,
            "processCPUmsPerDrawDelta": describe(deltas), "absoluteControlToControlSpreadMs": describe(control_spread),
            "repeatablePositiveCostAboveObservedControlSpread": resolved,
            "conclusion": "positive cost exceeds observed control spread in every block" if resolved else "cost not resolved above control spread; never infer zero overhead",
            "limits": ["Common observer cost excluded; not total instrumentation overhead", "Interactive host; control spread is not a confidence interval",
                       "No subtraction/correction of earlier baseline percentiles", "No GPU overhead, memory, energy, fullscreen or tvOS acceptance"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    print(json.dumps(analyze(args.directory), indent=2, allow_nan=False))


if __name__ == "__main__":
    main()
