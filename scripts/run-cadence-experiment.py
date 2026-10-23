#!/usr/bin/env python3
"""Five blocks: alternate variants, bracket each timeline run with two controls."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for variant in ["before", "after"]:
        parser.add_argument(f"--{variant}-binary", type=Path, required=True)
        parser.add_argument(f"--{variant}-revision", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(exist_ok=False, parents=True)
    suite = {"kind": "five-bracketed-timeline-pairs", "runs": []}
    for block in range(1, 6):
        for variant in (["before", "after"] if block % 2 else ["after", "before"]):
            for mode in ["control1", "timeline", "control2"]:
                directory = f"{block:02}-{variant}-{mode}"
                command = [sys.executable, str(ROOT / "scripts/run-feed-performance.py"),
                           "--binary", str(getattr(args, variant + "_binary")),
                           "--revision", getattr(args, variant + "_revision"),
                           "--output", str(args.output / directory), "--runs", "1"]
                if mode == "timeline":
                    command.append("--timeline")
                result = subprocess.run(command, cwd=ROOT, timeout=150)
                suite["runs"].append({"block": block, "variant": variant, "mode": mode,
                                      "directory": directory, "command": command, "exitCode": result.returncode})
                (args.output / "suite.json").write_text(json.dumps(suite, indent=2) + "\n")
                print(f"block {block}/5 {variant} {mode}: exit={result.returncode}", flush=True)
                if result.returncode:
                    raise SystemExit("Failed run retained; no replacement or acceptance")


if __name__ == "__main__":
    main()
