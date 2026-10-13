#!/usr/bin/env python3
"""Record settings with Screener and reject incomplete Swift Testing runs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix="dreams-gui-") as feed:
        result = subprocess.run(
            ["swift", "test", "-c", "release", "--filter", "SettingsPageTests"],
            cwd=ROOT,
            env=dict(os.environ, DREAMS_RECORD_GUI="1", DREAMS_FEED_DIRECTORY=feed),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=300,
        )
    print(result.stdout, end="", flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
    paths = [line.removeprefix("DREAMS_GUI_TRACE=") for line in result.stdout.splitlines()
             if line.startswith("DREAMS_GUI_TRACE=")]
    assert len(paths) == 1, "Runner exited without finishing the recorded scenario"
    trace = Path(paths[0])
    records = [json.loads(line) for line in (trace / "timeline.jsonl").read_text().splitlines()]
    assert records[0]["kind"] == "sessionStarted"
    assert records[-1]["kind"] == "sessionEnded", "Incomplete Screener lifecycle"
    assert not any(r.get("name") == "Scenario.failed" for r in records)
    frames = [r for r in records if r["kind"] == "keyframe"]
    assert len(frames) == 13, f"Expected 13 settings checkpoints, got {len(frames)}"
    assert all((trace / r["blob"]).is_file() for r in frames)
    print(f"PASS: complete Screener settings trace, {len(frames)} frames: {trace}")


if __name__ == "__main__":
    main()
