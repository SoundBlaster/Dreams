#!/usr/bin/env python3
"""Prove bracketing arithmetic, source identity checks and missing data semantics."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location("calibration_analysis", Path(__file__).with_name("analyze-calibration.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def expect_rejection(root):
    try:
        module.analyze(root)
    except ValueError:
        return
    raise AssertionError("Incompatible calibration inputs were accepted")


with tempfile.TemporaryDirectory(prefix="dreams-calibration-test-") as directory:
    root = Path(directory)
    fixture = b'{"name":"synthetic"}\n'
    digest = hashlib.sha256(fixture).hexdigest()
    suite = {"order": ["control", "full", "control"], "blocks": 1, "runKind": "calibration", "runs": []}
    for position, (mode, seconds) in enumerate([("control", 0.006), ("full", 0.012), ("control", 0.012)], start=1):
        name = f"01-{position}-{mode}"
        folder = root / name
        folder.mkdir()
        (folder / "scenario.json").write_bytes(fixture)
        manifest = {"revision": "source", "binarySHA256": "binary", "fixtureSHA256": digest,
                    "machine": "arm64", "hardwareModel": "model", "cpuModel": "cpu",
                    "resourceSHA256": {"font": "font"}, "runKind": "calibration", "calibrationMode": mode,
                    "results": [{"exitCode": 0, "valid": True}]}
        cal = {"mode": mode, "cpu": {"userSeconds": seconds, "systemSeconds": 0}, "processCPUSecondsPerDraw": seconds / 3,
               "samples": [{"presentedAt": time} for time in [10, 10.033, 10.066]], "draw": {"count": 3, "p50": 0.002, "p95": 0.004},
               "presentation": {"count": 2, "p99": 0.033}, "pendingCallbacks": 0, "overflow": 0, "unavailableDrawable": 0,
               "unpresentedSamples": 0, "intervalsOver50ms": 0, "intervalsOver100ms": 0}
        report = {"schemaVersion": 2, "revision": "source", "fixtureSHA256": digest, "valid": True,
                  "device": "test", "os": "test", "backingScale": 2, "screenMaximumFPS": 60, "screenFrame": "test",
                  "thermalStates": [0], "measuredSeconds": 60, "samples": [] if mode == "control" else [None] * 3, "calibration": cal}
        (folder / "manifest.json").write_text(json.dumps(manifest))
        (folder / "run-01.json").write_text(json.dumps(report))
        suite["runs"].append({"block": 1, "position": position, "mode": mode, "directory": name, "exitCode": 0})
    (root / "suite.json").write_text(json.dumps(suite))
    result = module.analyze(root)
    assert result["complete"] and not result["sufficientRepeats"]
    assert "insufficient repeats" in result["conclusion"]
    assert result["identities"][0]["hardwareModel"] == "model"
    assert abs(result["blocks"][0]["processCPUmsPerDraw"]["delta"] - 1) < 1e-9
    assert result["absoluteControlToControlSpreadMs"]["median"] == 2
    assert not result["repeatablePositiveCostAboveObservedControlSpread"]
    full_path = root / "01-2-full/run-01.json"
    full = json.loads(full_path.read_text())
    full["calibration"]["cpu"] = {"userSeconds": 0.003, "systemSeconds": 0}
    full["calibration"]["processCPUSecondsPerDraw"] = 0.001
    full_path.write_text(json.dumps(full))
    assert module.analyze(root)["processCPUmsPerDrawDelta"]["median"] == -2
    full["calibration"]["cpu"] = None
    full["calibration"]["processCPUSecondsPerDraw"] = None
    full_path.write_text(json.dumps(full))
    invalid = module.analyze(root)
    assert not invalid["complete"] and invalid["runs"][1]["processCPUmsPerDraw"] is None
    assert "invalid or incomplete" in invalid["conclusion"]
    manifest_path = root / "01-3-control/manifest.json"
    changed = json.loads(manifest_path.read_text())
    changed["binarySHA256"] = "different"
    manifest_path.write_text(json.dumps(changed))
    expect_rejection(root)
    changed["binarySHA256"] = "binary"
    changed["cpuModel"] = "different cpu"
    manifest_path.write_text(json.dumps(changed))
    expect_rejection(root)
    changed["cpuModel"] = "cpu"
    manifest_path.write_text(json.dumps(changed))
    (root / "01-3-control/scenario.json").write_text("{}")
    expect_rejection(root)

print("PASS: bracketing/negative deltas, missing CPU, repeat counts and mixed binary/fixture rejection")
