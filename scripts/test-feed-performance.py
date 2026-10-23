#!/usr/bin/env python3
"""Guard event identity, missing delivery and diagnostic scope without launching UI."""
import copy
import importlib.util
from pathlib import Path
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


analysis = load("feed_analysis", "analyze-feed-performance.py")
runner = load("feed_runner", "run-feed-performance.py")


class FeedPerformanceTests(unittest.TestCase):
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
