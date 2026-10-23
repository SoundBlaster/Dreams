#!/usr/bin/env python3
"""Protect clock semantics, complete block requirements and experiment identity."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("cadence", Path(__file__).with_name("analyze-cadence.py"))
cadence = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cadence)


def report():
    return {"schemaVersion": 4, "timelineMode": "commit-bracket-gpu-absolute-v1", "samples": [
        {"id": 7, "submittedAt": 9.99, "presentedAt": 10.02, "gpuSeconds": .002,
         "gpuCompleted": True, "gpuFailed": False,
         "timeline": {"commitBeganAt": 10, "commitReturnedAt": 10.004,
                      "gpuStartedAt": 10.001, "gpuEndedAt": 10.003}}]}


class CadenceTests(unittest.TestCase):
    def test_gpu_overlap_keeps_signed_queue_bound(self):
        value = cadence.timeline(report())
        self.assertAlmostEqual(value["metrics"]["gpuWaitLowerBoundMs"]["p50"], -3)
        self.assertAlmostEqual(value["metrics"]["gpuWaitUpperBoundMs"]["p50"], 1)
        self.assertAlmostEqual(value["metrics"]["gpuEndToPresentedMs"]["p50"], 17)
        self.assertEqual(value["gpuStartsBeforeCommitReturns"], 1)

    def test_missing_nonfinite_or_inconsistent_clocks_are_rejected(self):
        for key, value in [("gpuStartedAt", None), ("gpuEndedAt", float('nan')),
                           ("commitReturnedAt", 9), ("gpuEndedAt", 10.03)]:
            with self.subTest(key=key, value=value):
                invalid = copy.deepcopy(report())
                invalid["samples"][0]["timeline"][key] = value
                with self.assertRaises(ValueError):
                    cadence.timeline(invalid)
        with self.assertRaises(ValueError):
            cadence.timeline({"schemaVersion": 3})

    def test_incomplete_or_duplicate_blocks_are_not_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'suite.json').write_text(json.dumps({"runs": []}))
            with self.assertRaises(ValueError):
                cadence.analyze(root)

    def test_cost_stays_signed_and_mixed_identity_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runs = [{"block": b, "variant": v, "mode": m, "directory": f"{b}-{v}-{m}", "exitCode": 0}
                    for b in range(1, 6) for v in (['before', 'after'] if b % 2 else ['after', 'before'])
                    for m in ['control1', 'timeline', 'control2']]
            (root / 'suite.json').write_text(json.dumps({"runs": runs}))

            def one(path, enabled):
                variant = 'before' if 'before' in path.name else 'after'
                return {"identity": {"fixture": 1}, "revision": variant, "binarySHA256": variant,
                        "cpuMsPerDraw": 1 if enabled else 2, "feed": {}, "timeline": {},
                        "collectionBeganAt": next(i for i, r in enumerate(runs) if r['directory'] == path.name) * 100 + 1,
                        "lastPresentedAt": next(i for i, r in enumerate(runs) if r['directory'] == path.name) * 100 + 61}

            with patch.object(cadence, 'one_run', side_effect=one):
                value = cadence.analyze(root)
                self.assertEqual(value['overhead'][0]['timelineMinusControlMsPerDraw'], -1)
                self.assertEqual(len(value['pairs']), 5)

            def mixed(path, enabled):
                value = one(path, enabled)
                if path.name == '3-after-timeline':
                    value['identity'] = {"fixture": 2}
                return value

            with patch.object(cadence, 'one_run', side_effect=mixed), self.assertRaises(ValueError):
                cadence.analyze(root)

            (root / 'suite.json').write_text(json.dumps({"runs": list(reversed(runs))}))
            with patch.object(cadence, 'one_run', side_effect=one), self.assertRaises(ValueError):
                cadence.analyze(root)
            (root / 'suite.json').write_text(json.dumps({"runs": runs}))

            def overlap(path, enabled):
                value = one(path, enabled)
                if path.name == '3-after-timeline':
                    value['collectionBeganAt'] -= 100
                return value

            with patch.object(cadence, 'one_run', side_effect=overlap), self.assertRaises(ValueError):
                cadence.analyze(root)


if __name__ == '__main__':
    unittest.main()
