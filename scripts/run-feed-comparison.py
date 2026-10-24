#!/usr/bin/env python3
"""Run five alternating, fully identified before/after feed pairs."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before-binary", type=Path, required=True)
    parser.add_argument("--before-revision", required=True)
    parser.add_argument("--after-binary", type=Path, default=ROOT / "dist/Dreams.app/Contents/MacOS/Dreams")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    suite = {"kind": "five-alternating-feed-pairs", "runnerRevision": revision, "runs": []}
    for pair in range(1, 6):
        for variant in (["before", "after"] if pair % 2 else ["after", "before"]):
            directory = args.output / f"{pair:02}-{variant}"
            command = [sys.executable, str(ROOT / "scripts/run-feed-performance.py"),
                       "--binary", str(args.before_binary if variant == "before" else args.after_binary),
                       "--revision", args.before_revision if variant == "before" else revision,
                       "--output", str(directory), "--runs", "1"]
            result = subprocess.run(command, cwd=ROOT, timeout=150)
            suite["runs"].append({"pair": pair, "variant": variant, "directory": directory.name,
                                  "command": command, "exitCode": result.returncode})
            (args.output / "suite.json").write_text(json.dumps(suite, indent=2) + "\n")
            print(f"pair {pair}/5 {variant}: exit={result.returncode}", flush=True)
            if result.returncode:
                raise SystemExit("Invalid run retained; comparison incomplete")


if __name__ == "__main__":
    main()
