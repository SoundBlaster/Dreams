#!/usr/bin/env python3
"""Compare identified feed pairs without pooling events or auto-accepting a fix."""
import argparse
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location("feed_analysis", Path(__file__).with_name("analyze-feed-performance.py"))
analysis = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analysis)


def compare(directory):
    suite = json.loads((directory / "suite.json").read_text())
    slots = [(r["pair"], r["variant"]) for r in suite["runs"]]
    expected = {(p, v) for p in range(1, 6) for v in ["before", "after"]}
    if len(slots) != 10 or set(slots) != expected:
        raise ValueError("Five complete distinct pairs required")
    inputs = {}
    identity = None
    variants = {}
    for item in suite["runs"]:
        path = directory / item["directory"]
        value = analysis.analyze(path)
        manifest = json.loads((path / "manifest.json").read_text())
        scenario = json.loads((path / "scenario.json").read_text())
        if (item["exitCode"] != 0 or not value["allValid"] or len(value["runs"]) != 1
                or value["runKind"] != "feed-baseline" or scenario["warmupSeconds"] != 30 or scenario["measureSeconds"] != 60):
            raise ValueError("Invalid, smoke or differently bounded run")
        common = {k: manifest[k] for k in ["fixtureSHA256", "traceSHA256", "resourceSHA256", "hardwareModel", "cpuModel", "sdk", "toolchain"]}
        common["display"] = value["identity"]
        if identity is not None and common != identity:
            raise ValueError("Mismatched fixture/resources/hardware/display identity")
        identity = common
        variant = item["variant"]
        source = {k: manifest[k] for k in ["revision", "binarySHA256"]}
        if variant in variants and source != variants[variant]:
            raise ValueError("Variant binary or source changed between pairs")
        variants[variant] = source
        row = value["runs"][0]
        if row["thermalStates"] != [0]:
            raise ValueError("Thermal-confounded run retained; no controlled comparison")
        expected_mode = "shared-background" if variant == "after" else "synchronous-frame"
        if row.get("feedReadMode", "synchronous-frame") != expected_mode:
            raise ValueError("Wrong reader implementation for variant")
        inputs[(item["pair"], variant)] = row
    if variants["before"]["binarySHA256"] == variants["after"]["binarySHA256"]:
        raise ValueError("Before and after cannot use the same executable")
    pairs = []
    for number in range(1, 6):
        before, after = (inputs[(number, v)] for v in ["before", "after"])
        pairs.append({"pair": number, "before": before, "after": after,
                      "deliveryP95DeltaMs": after["eventLatencyMs"]["p95"] - before["eventLatencyMs"]["p95"],
                      "over50msDelta": after["intervalsOver50ms"] - before["intervalsOver50ms"],
                      "over100msDelta": after["intervalsOver100ms"] - before["intervalsOver100ms"]})
    return {"schemaVersion": 1, "identity": identity, "variants": variants, "pairs": pairs,
            "allEventsDelivered": True,
            "allAfterReadsOffMain": all(p["after"]["mainThreadRefreshes"] == 0 for p in pairs),
            "deliveryP95ImprovedEveryPair": all(p["deliveryP95DeltaMs"] < 0 for p in pairs),
            "longIntervalsDidNotIncreaseEveryPair": all(p["over50msDelta"] <= 0 and p["over100msDelta"] <= 0 for p in pairs),
            "acceptance": "descriptive evidence; owner review required; no automatic issue closure",
            "limits": "Presented-letter proxy, not pixels/full text. Snapshot thread observations plus source audit, not syscall tracing. No total CPU/energy/TV/multi-display claim; added observer overhead uncalibrated."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    print(json.dumps(compare(args.directory), indent=2, ensure_ascii=False))
