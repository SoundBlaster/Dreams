#!/usr/bin/env python3
"""Run opt-in Metal capture diagnostics. No TCC requests or settings changes."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--screener-path", type=Path, required=True,
                        help="Local Screener checkout containing ScreenerScreenCaptureKit")
    args = parser.parse_args()
    screener_path = args.screener_path.resolve()
    if not (screener_path / "Sources/ScreenerScreenCaptureKit").is_dir():
        parser.error("--screener-path must contain the new optional backend")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output = ROOT / "artifacts" / "metal-pilot" / stamp
    output.mkdir(parents=True)
    env = dict(os.environ, DREAMS_METAL_PILOT="1", DREAMS_SCREENER_PATH=str(screener_path))
    metrics = {"sourceRevision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()}
    metrics["screenerPath"] = str(screener_path)
    metrics["screenerRevision"] = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=screener_path, text=True).strip()
    metrics["screenerSourceSHA256"] = {
        str(p.relative_to(screener_path)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted((screener_path / "Sources").rglob("*.swift"))
        if "ScreenerKit" in p.parts or "ScreenerScreenCaptureKit" in p.parts
    }
    if not args.skip_build:
        start = time.monotonic()
        with (output / "build.log").open("w") as log:
            subprocess.run(["swift", "build", "-c", "release"], cwd=ROOT, env=env,
                           stdout=log, stderr=subprocess.STDOUT, timeout=300, check=True)
        metrics["buildSeconds"] = time.monotonic() - start
    binary = Path(subprocess.check_output(["swift", "build", "-c", "release", "--show-bin-path"],
                                         cwd=ROOT, env=env, text=True).strip()) / "Dreams"
    binary_data = binary.read_bytes()
    if b"METAL_PILOT_COMPLETE=" not in binary_data or b"ScreenerScreenCaptureKit.window" not in binary_data:
        raise RuntimeError("Cached binary lacks packaged-backend pilot instrumentation; rerun without --skip-build")
    metrics["binarySHA256"] = hashlib.sha256(binary_data).hexdigest()
    runs = []
    for name, flags in [("transparent-1", []), ("transparent-2", []),
                        ("opaque", ["--pilot-opaque"]), ("live", ["--pilot-live"]),
                        ("production-surface", ["--pilot-production-surface"])]:
        run = output / name
        (run / "feed").mkdir(parents=True)
        start = time.monotonic()
        with (run / "process.log").open("w") as log:
            result = subprocess.run([str(binary), "--capture-metal-pilot", str(run), *flags],
                                    cwd=ROOT, env=dict(env, DREAMS_FEED_DIRECTORY=str(run / "feed")),
                                    stdout=log, stderr=subprocess.STDOUT, timeout=75)
        if result.returncode or not (run / "manifest.json").is_file() or (run / "failure.txt").exists():
            raise RuntimeError(f"Pilot did not complete: {run}")
        manifest = json.loads((run / "manifest.json").read_text())
        trace = Path(manifest["trace"])
        events = [json.loads(line) for line in (trace / "timeline.jsonl").read_text().splitlines()]
        if events[-1]["kind"] != "sessionEnded":
            raise RuntimeError(f"Incomplete trace: {trace}")
        for event in events:
            if "blob" in event and not (trace / event["blob"]).is_file():
                raise RuntimeError(f"Missing trace image: {event}")
        runs.append({"name": name, "seconds": time.monotonic() - start,
                     "trace": str(trace), "rows": len(manifest["rows"])})
        print(f"Completed {name}: {runs[-1]['seconds']:.3f}s", flush=True)
    metrics["runs"] = runs
    (output / "run.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(output)


if __name__ == "__main__":
    main()
