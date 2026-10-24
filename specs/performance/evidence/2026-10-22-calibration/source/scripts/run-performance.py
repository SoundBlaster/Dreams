#!/usr/bin/env python3
"""Run bounded macOS probes; reports contain no live mailbox or user preferences."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=ROOT / "dist/Dreams.app/Contents/MacOS/Dreams")
    parser.add_argument("--scenario", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--smoke", action="store_true", help="1s warmup + 3s collection; never baseline evidence")
    parser.add_argument("--calibration", choices=["control", "full"], help="common observer with nil or full collector")
    args = parser.parse_args()
    if not 1 <= args.runs <= 10:
        parser.error("--runs must be 1...10")
    args.output.mkdir(parents=True, exist_ok=False)
    scenario = json.loads(args.scenario.read_text())
    if args.smoke:
        scenario.update(warmupSeconds=1, measureSeconds=3)
    fixture = args.output.resolve() / "scenario.json"
    fixture.write_text(json.dumps(scenario, indent=2) + "\n")
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    dirty = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)
    resources = args.binary.parent.parent / "Resources/Dreams_Dreams.bundle"
    if (resources / "Contents/Resources").is_dir():
        resources = resources / "Contents/Resources"
    manifest = {
        "schemaVersion": 2 if args.calibration else 1,
        "runKind": "smoke" if args.smoke else "calibration" if args.calibration else "baseline",
        "calibrationMode": args.calibration,
        "revision": revision,
        "workingTreeStatus": dirty,
        "binarySHA256": digest(args.binary),
        "resourceSHA256": {name: digest(resources / name) for name in ["Rain.metal", "DreamsMatrix.ttf", "Matrix-Code.ttf"]},
        "fixtureSHA256": digest(fixture),
        "machine": platform.machine(),
        "hardwareModel": subprocess.check_output(["sysctl", "-n", "hw.model"], text=True).strip(),
        "cpuModel": subprocess.check_output(["sysctl", "-n", "machdep.cpu.brand_string"], text=True).strip(),
        "toolchain": subprocess.check_output(["swift", "--version"], text=True).strip(),
        "sdk": subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-version"], text=True).strip(),
        "command": [str(args.binary.resolve()), "--performance-calibration" if args.calibration else "--performance-run", str(fixture)],
        "results": [],
    }
    manifest_path = args.output / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    for run in range(1, args.runs + 1):
        report = args.output.resolve() / f"run-{run:02}.json"
        command = manifest["command"] + [str(report)] + ([args.calibration] if args.calibration else [])
        with tempfile.TemporaryDirectory(prefix="dreams-perf-mailbox-") as mailbox:
            env = os.environ | {"DREAMS_FEED_DIRECTORY": mailbox, "DREAMS_PERF_REVISION": revision}
            with (args.output / f"run-{run:02}.log").open("w") as log:
                result = subprocess.run(command,
                                        env=env, stdout=log, stderr=subprocess.STDOUT,
                                        timeout=scenario["warmupSeconds"] + scenario["measureSeconds"] + 120)
        data = json.loads(report.read_text()) if report.exists() else {}
        valid = result.returncode == 0 and data.get("valid", False)
        if args.calibration:
            valid = valid and data.get("calibration", {}).get("mode") == args.calibration
        manifest["results"].append({"file": report.name, "exitCode": result.returncode, "valid": valid, "command": command})
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"{scenario['name']} {run}/{args.runs}: valid={valid}", flush=True)
        if not valid:
            raise SystemExit("Invalid run retained; do not use it as a successful baseline.")


if __name__ == "__main__":
    main()
