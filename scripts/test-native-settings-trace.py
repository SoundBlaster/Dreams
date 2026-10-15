#!/usr/bin/env python3
"""Record explicit native-form states with Screener; distinguish hierarchy from screen evidence."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix="dreams-native-feed-") as feed:
        result = subprocess.run(
            ["swift", "test", "-c", "release", "--filter", "recordNativeFormsWithScreener"], cwd=ROOT,
            env=dict(os.environ, DREAMS_RECORD_NATIVE_SETTINGS="1", DREAMS_FEED_DIRECTORY=feed),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=300,
        )
    print(result.stdout, end="", flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
    paths = [line.removeprefix("DREAMS_NATIVE_SETTINGS_TRACE=") for line in result.stdout.splitlines()
             if line.startswith("DREAMS_NATIVE_SETTINGS_TRACE=")]
    assert len(paths) == 1, "Recorded scenario did not complete"
    trace = Path(paths[0])
    records = [json.loads(line) for line in (trace / "timeline.jsonl").read_text().splitlines()]
    assert records[0]["kind"] == "sessionStarted" and records[-1]["kind"] == "sessionEnded"
    assert not any(record.get("name") == "Scenario.failed" for record in records)
    frames = [record for record in records if record["kind"] == "keyframe"]
    assert len(frames) == 13
    assert all((trace / record["blob"]).is_file() for record in frames)
    backend = os.environ.get("DREAMS_NATIVE_CAPTURE_BACKEND", "hierarchy")
    print(f"PASS: complete Screener native settings trace, {len(frames)} {backend} frames: {trace}")


if __name__ == "__main__":
    main()
