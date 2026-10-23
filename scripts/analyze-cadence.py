#!/usr/bin/env python3
"""Analyze commit/GPU/presentation timing and bracketed observer cost without auto-acceptance."""
import argparse
import importlib.util
import json
import math
from pathlib import Path
import statistics

spec = importlib.util.spec_from_file_location("feed", Path(__file__).with_name("analyze-feed-performance.py"))
feed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feed)


def metric(values):
    if not values or any(not math.isfinite(x) for x in values):
        raise ValueError("Missing/nonfinite timeline metric")
    ordered = sorted(values)
    return {"count": len(values)} | {key: ordered[math.ceil(len(values) * rank) - 1]
                                   for key, rank in [("p50", .5), ("p95", .95), ("p99", .99), ("max", 1)]}


def timeline(report):
    if report.get("schemaVersion") != 4 or report.get("timelineMode") != "commit-bracket-gpu-absolute-v1":
        raise ValueError("Absolute timeline report required")
    frames = []
    samples = sorted(report["samples"], key=lambda s: s.get("presentedAt", 0))
    for index, sample in enumerate(samples):
        clock = sample.get("timeline", {})
        values = [clock.get(k) for k in ["commitBeganAt", "commitReturnedAt", "gpuStartedAt", "gpuEndedAt"]]
        if any(not isinstance(x, (int, float)) or not math.isfinite(x) or x <= 0 for x in values):
            raise ValueError("Missing/invalid absolute frame timestamps")
        began, returned, gpu_start, gpu_end = values
        shown = sample.get("presentedAt", 0)
        if (not sample.get("gpuCompleted") or sample.get("gpuFailed") or not math.isfinite(shown)
                or began < sample["submittedAt"] or returned < began or gpu_start < began - 1e-6
                or gpu_end <= gpu_start or shown < gpu_end - 1e-6
                or abs(gpu_end - gpu_start - sample["gpuSeconds"]) > 1e-6):
            raise ValueError("Inconsistent command/GPU/presentation clocks")
        frames.append({"frame": sample["id"], "drawBeganAt": sample["submittedAt"], **clock,
                       "presentedAt": shown,
                       "presentationIntervalMs": None if index == 0 else (shown - samples[index - 1]["presentedAt"]) * 1000,
                       "preCommitMs": (began - sample["submittedAt"]) * 1000,
                       "commitCallMs": (returned - began) * 1000,
                       "gpuWaitLowerBoundMs": (gpu_start - returned) * 1000,
                       "gpuWaitUpperBoundMs": (gpu_start - began) * 1000,
                       "gpuMs": (gpu_end - gpu_start) * 1000,
                       "gpuEndToPresentedMs": (shown - gpu_end) * 1000})
    keys = ["preCommitMs", "commitCallMs", "gpuWaitLowerBoundMs", "gpuWaitUpperBoundMs", "gpuMs", "gpuEndToPresentedMs"]
    return {"metrics": {k: metric([r[k] for r in frames]) for k in keys},
            "gaps": [r for r in frames if (r["presentationIntervalMs"] or 0) > 50],
            "gpuStartsBeforeCommitReturns": sum(r["gpuWaitLowerBoundMs"] < 0 for r in frames),
            "limits": "Commit is an API bracket, not exact driver enqueue. Signed lower bounds preserve overlap. Drawable timestamp, not physical scanout; no causal attribution."}


def one_run(directory, enabled):
    value = feed.analyze(directory)
    manifest = json.loads((directory / "manifest.json").read_text())
    scenario = json.loads((directory / "scenario.json").read_text())
    if (not value["allValid"] or len(value["runs"]) != 1 or value["runKind"] != "feed-baseline"
            or scenario["warmupSeconds"] != 30 or scenario["measureSeconds"] != 60
            or value["runs"][0]["thermalStates"] != [0] or manifest.get("timelineEnabled") != enabled):
        raise ValueError("Invalid, smoke, thermal-confounded or wrong observation mode")
    report = feed.reports.read_report(directory / manifest["results"][0]["file"])
    cpu = report.get("collectionCPU", {})
    values = [cpu.get(k) for k in ["userSeconds", "systemSeconds"]]
    if any(not isinstance(x, (int, float)) or not math.isfinite(x) or x < 0 for x in values):
        raise ValueError("Missing/invalid collection CPU")
    if bool(report.get("timelineMode")) != enabled or (not enabled and any(s.get("timeline") for s in report["samples"])):
        raise ValueError("Observation mode does not match report")
    common = {k: manifest[k] for k in ["fixtureSHA256", "traceSHA256", "resourceSHA256", "hardwareModel", "cpuModel", "sdk", "toolchain"]}
    common["display"] = value["identity"]
    return {"identity": common, "revision": manifest["revision"], "binarySHA256": manifest["binarySHA256"],
            "feed": value["runs"][0], "cpuMsPerDraw": sum(values) * 1000 / len(report["samples"]),
            "timeline": timeline(report) if enabled else None,
            "recordedFrames": len(report["samples"]), "measuredSeconds": report["measuredSeconds"],
            "unavailableDrawable": report["unavailableDrawable"],
            "collectionBeganAt": min(s["submittedAt"] for s in report["samples"]),
            "lastPresentedAt": max(s["presentedAt"] for s in report["samples"])}


def analyze(directory):
    suite = json.loads((directory / "suite.json").read_text())
    expected = {(b, v, m) for b in range(1, 6) for v in ["before", "after"] for m in ["control1", "timeline", "control2"]}
    slots = [(r["block"], r["variant"], r["mode"]) for r in suite["runs"]]
    if len(slots) != 30 or set(slots) != expected:
        raise ValueError("Five complete bracketed blocks for both variants required")
    order = [(b, v, m) for b in range(1, 6)
             for v in (["before", "after"] if b % 2 else ["after", "before"])
             for m in ["control1", "timeline", "control2"]]
    if slots != order:
        raise ValueError("Wrong C/F/C or alternating implementation order")
    inputs, identity, variants = {}, None, {}
    previous_end = None
    for item in suite["runs"]:
        if item["exitCode"] != 0:
            raise ValueError("Incomplete/failed run retained")
        value = one_run(directory / item["directory"], item["mode"] == "timeline")
        if previous_end is not None and value["collectionBeganAt"] <= previous_end:
            raise ValueError("Overlapping or reordered collection clocks")
        previous_end = value["lastPresentedAt"]
        if identity is not None and value["identity"] != identity:
            raise ValueError("Mixed fixture/resource/hardware identity")
        identity = value["identity"]
        variant = item["variant"]
        source = {k: value[k] for k in ["revision", "binarySHA256"]}
        if variant in variants and variants[variant] != source:
            raise ValueError("Variant executable/source changed")
        variants[variant] = source
        inputs[(item["block"], variant, item["mode"])] = value
    if variants["before"]["binarySHA256"] == variants["after"]["binarySHA256"]:
        raise ValueError("Distinct implementations required")
    overhead, pairs = [], []
    for block in range(1, 6):
        for variant in ["before", "after"]:
            c1, full, c2 = (inputs[(block, variant, m)] for m in ["control1", "timeline", "control2"])
            overhead.append({"block": block, "variant": variant,
                             "timelineMinusControlMsPerDraw": full["cpuMsPerDraw"] - statistics.mean([c1["cpuMsPerDraw"], c2["cpuMsPerDraw"]]),
                             "controlSpreadMsPerDraw": abs(c1["cpuMsPerDraw"] - c2["cpuMsPerDraw"]),
                             "control1": c1["cpuMsPerDraw"], "timeline": full["cpuMsPerDraw"], "control2": c2["cpuMsPerDraw"]})
        pairs.append({"pair": block, **{v: inputs[(block, v, "timeline")] for v in ["before", "after"]}})
    return {"identity": identity, "variants": variants, "overhead": overhead, "pairs": pairs,
            "acceptance": "Descriptive evidence only. Signed incremental cost vs control spread; common observer excluded. No automatic issue closure or cadence acceptance; no pooling quantiles."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    print(json.dumps(analyze(args.directory), indent=2))
