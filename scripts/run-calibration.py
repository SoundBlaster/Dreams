#!/usr/bin/env python3
"""Run fixed control/full/control blocks serially; never alter the owner's session."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenario", type=Path, default=ROOT / "research/performance/scenarios/dense.json")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--blocks", type=int, default=5)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    if not 1 <= args.blocks <= 10 or (args.smoke and args.blocks != 1):
        parser.error("--blocks must be 1...10; smoke requires --blocks 1")
    args.output.mkdir(parents=True, exist_ok=False)
    suite = {"schemaVersion": 1, "runKind": "smoke" if args.smoke else "calibration", "blocks": args.blocks,
             "order": ["control", "full", "control"], "runs": []}
    for block in range(1, args.blocks + 1):
        for position, mode in enumerate(suite["order"], start=1):
            destination = args.output.resolve() / f"{block:02}-{position}-{mode}"
            command = [sys.executable, str(ROOT / "scripts/run-performance.py"), "--scenario", str(args.scenario.resolve()),
                       "--output", str(destination), "--runs", "1", "--calibration", mode]
            if args.binary:
                command += ["--binary", str(args.binary.resolve())]
            if args.smoke:
                command += ["--smoke"]
            began = time.time()
            print(f"START block={block} position={position} mode={mode}", flush=True)
            child = subprocess.run(command, cwd=ROOT, check=False)
            suite["runs"].append({"block": block, "position": position, "mode": mode, "directory": destination.name,
                                  "beganUnix": began, "endedUnix": time.time(), "exitCode": child.returncode})
            (args.output / "suite.json").write_text(json.dumps(suite, indent=2) + "\n")
            if child.returncode:
                raise SystemExit("Invalid calibration run retained; suite stopped.")
    print("CALIBRATION_COMPLETE", flush=True)


if __name__ == "__main__":
    main()
