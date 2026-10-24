#!/usr/bin/env python3
"""Guard event identity, missing delivery and diagnostic scope without launching UI."""
import copy
import importlib.util
from pathlib import Path
import subprocess
import sys
import json
import tempfile
import unittest
from unittest.mock import patch
import uuid

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


analysis = load("feed_analysis", "analyze-feed-performance.py")
runner = load("feed_runner", "run-feed-performance.py")
comparison = load("feed_comparison", "compare-feed-performance.py")


class FeedPerformanceTests(unittest.TestCase):
    def test_comparison_requires_complete_matching_nominal_pairs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            suite = {"runs": []}
            def summary(path):
                after = path.name.endswith("after")
                row = {"thermalStates": [0], "eventLatencyMs": {"p95": 100 if after else 800},
                       "mainThreadRefreshes": 0 if after else 60, "intervalsOver50ms": 0, "intervalsOver100ms": 0}
                if after:
                    row["feedReadMode"] = "shared-background"
                return {"allValid": True, "runs": [row], "runKind": "feed-baseline", "identity": {"device": "test"}}
            for pair in range(1, 6):
                for variant in ["before", "after"]:
                    path = root / f"{pair}-{variant}"
                    path.mkdir()
                    manifest = {k: "same" for k in ["fixtureSHA256", "traceSHA256", "resourceSHA256", "hardwareModel", "cpuModel", "sdk", "toolchain"]}
                    manifest.update(revision=variant, binarySHA256=variant)
                    (path / "manifest.json").write_text(json.dumps(manifest))
                    (path / "scenario.json").write_text('{"warmupSeconds":30,"measureSeconds":60}')
                    suite["runs"].append({"pair": pair, "variant": variant, "directory": path.name, "exitCode": 0})
            (root / "suite.json").write_text(json.dumps(suite))
            with patch.object(comparison.analysis, "analyze", side_effect=summary):
                self.assertTrue(comparison.compare(root)["deliveryP95ImprovedEveryPair"])
                path = root / "1-after/manifest.json"
                manifest = json.loads(path.read_text())
                manifest["resourceSHA256"] = "different"
                path.write_text(json.dumps(manifest))
                with self.assertRaisesRegex(ValueError, "Mismatched"):
                    comparison.compare(root)
                suite["runs"].pop()
                (root / "suite.json").write_text(json.dumps(suite))
                with self.assertRaisesRegex(ValueError, "Five complete"):
                    comparison.compare(root)

    @unittest.skipUnless(sys.platform == "darwin", "macOS host clock")
    def test_host_clock_epoch_is_shared_across_processes(self):
        before = runner.host_time()
        child = float(subprocess.check_output([sys.executable, "-c",
                      "import time; print(time.clock_gettime(time.CLOCK_UPTIME_RAW))"], text=True))
        after = runner.host_time()
        self.assertLessEqual(before, child)
        self.assertLessEqual(child, after)

    def fixture(self):
        trace = {"name": "test", "sessions": 24, "expiredFiles": 12, "expiryOffset": 1,
                 "events": [{"offset": 0, "label": "TEST"}]}
        identity = str(uuid.uuid5(uuid.NAMESPACE_URL, "dreams-feed/test/0"))
        publication = {"exitCode": 0, "remainingJSONFiles": 24,
                       "writes": [{"eventID": identity, "commitBegan": 10, "committed": 10.001, "scheduled": 10}]}
        sample = {"feedRefresh": {"began": 10.1, "ended": 10.104, "succeeded": True,
                                  "onMainThread": True, "messageCount": 24, "eventIDs": [identity.upper()]},
                  "eventLetters": [identity.upper()], "drawSeconds": .005,
                  "presentedAt": 10.2, "gpuCompleted": True, "gpuFailed": False, "glyphRasterizations": 1}
        report = {"schemaVersion": 3, "feedProbe": True, "valid": True, "samples": [sample],
                  "summaries": {"presentation_interval_seconds": {"count": 1, "p99": .033}},
                  "intervalsOver50ms": 0, "intervalsOver100ms": 0}
        return report, publication, trace

    def test_latency_uses_presentation_and_publication_bracket(self):
        report, publication, trace = self.fixture()
        result = analysis.analyze_run(report, publication, trace)
        self.assertTrue(result["valid"])
        self.assertAlmostEqual(result["snapshotMs"]["p95"], 4)
        self.assertAlmostEqual(result["events"][0]["presentationLatencyLowerMs"], 199)
        self.assertAlmostEqual(result["events"][0]["presentationLatencyUpperMs"], 200)

    def test_missing_wrong_event_or_gpu_failure_is_not_delivery(self):
        for change in [{"eventLetters": []}, {"eventLetters": [str(uuid.uuid4())]},
                       {"presentedAt": 0}, {"gpuFailed": True}]:
            report, publication, trace = self.fixture()
            report["samples"][0].update(change)
            result = analysis.analyze_run(report, publication, trace)
            self.assertFalse(result["valid"])
            self.assertIsNone(result["events"][0]["presentationLatencyUpperMs"])
            self.assertIsNone(result["eventLatencyMs"]["p99"])

    def test_receipt_and_expiry_are_required_separately(self):
        report, publication, trace = self.fixture()
        report["samples"][0]["feedRefresh"]["succeeded"] = False
        self.assertFalse(analysis.analyze_run(report, publication, trace)["valid"])
        report, publication, trace = self.fixture()
        publication["remainingJSONFiles"] = 36
        self.assertFalse(analysis.analyze_run(report, publication, trace)["valid"])

    def test_background_reads_do_not_depend_on_frame_consumption(self):
        report, publication, trace = self.fixture()
        read = report["samples"][0].pop("feedRefresh")
        read["onMainThread"] = False
        report.update(feedReadMode="shared-background", feedReads=[read])
        report["samples"][0]["feedSeconds"] = .00001
        result = analysis.analyze_run(report, publication, trace)
        self.assertTrue(result["valid"])
        self.assertEqual(result["mainThreadRefreshes"], 0)
        self.assertEqual(result["backgroundRefreshes"], 1)
        self.assertEqual(result["drawsConsumingFeed"], 0)
        report["feedReads"] = []
        self.assertFalse(analysis.analyze_run(report, publication, trace)["valid"])

    def test_generic_and_calibration_reports_are_rejected(self):
        for changed in [{"schemaVersion": 1}, {"calibration": {"mode": "control"}}, {"feedProbe": False}]:
            report, publication, trace = self.fixture()
            report.update(changed)
            with self.assertRaises(ValueError):
                analysis.analyze_run(report, publication, trace)

    def test_trace_bounds_and_late_events(self):
        _, _, trace = self.fixture()
        runner.validate_trace(trace, 60)
        for key, value in [("sessions", 25), ("expiredFiles", 25), ("expiryOffset", 60),
                           ("events", [{"offset": 59, "label": "TEST"}])]:
            invalid = copy.deepcopy(trace)
            invalid[key] = value
            with self.assertRaises(ValueError):
                runner.validate_trace(invalid, 60)


if __name__ == "__main__":
    unittest.main()
