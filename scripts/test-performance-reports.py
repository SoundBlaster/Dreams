#!/usr/bin/env python3
"""Check invalid/missing measurements and compressed evidence stay distinguishable."""
import gzip
import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location("performance_summary", Path(__file__).with_name("summarize-performance.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix="dreams-report-test-") as folder:
    root = Path(folder)
    manifest = {"results": [{"file": "run-01.json", "exitCode": 0}], "runKind": "smoke",
                "revision": "test", "binarySHA256": "test", "fixtureSHA256": "test"}
    report = {"valid": False, "samples": [], "intervalsOver50ms": 0, "intervalsOver100ms": 0,
              "summaries": {key: {"count": 0} for key in ["draw_seconds", "simulation_seconds", "instances_seconds",
                                                         "gpu_seconds", "presentation_interval_seconds"]}}
    (root / "manifest.json").write_text(json.dumps(manifest))
    (root / "scenario.json").write_text('{"name": "test"}')
    (root / "run-01.json.gz").write_bytes(gzip.compress(json.dumps(report).encode(), mtime=0))
    result = module.summarize(root)
    assert result["allValid"] is False
    row = result["runs"][0]
    for key in ["drawP95ms", "simulationP95ms", "instancesP95ms", "gpuP95ms", "presentationP99ms", "observedFPS"]:
        assert row[key] is None, (key, row[key])
    report["summaries"]["draw_seconds"] = {"count": 1, "p95": 0.004}
    (root / "run-01.json").write_text(json.dumps(report))
    assert module.summarize(root)["runs"][0]["drawP95ms"] == 4
    assert module.milliseconds({"count": 1, "p95": 0}, "p95") == 0
    report["calibration"] = {"mode": "control"}
    (root / "run-01.json").write_text(json.dumps(report))
    try:
        module.summarize(root)
    except ValueError as error:
        assert "analyze-calibration.py" in str(error)
    else:
        raise AssertionError("Control must not be summarized as a zero-cost full collector")

print("PASS: missing measurements stay null, invalid runs stay invalid, gzip and raw reports agree")
