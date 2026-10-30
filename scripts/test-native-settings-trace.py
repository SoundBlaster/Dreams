#!/usr/bin/env python3
"""Record explicit native-form states with Screener; distinguish hierarchy from screen evidence."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metal", action="store_true", help="record a short compositor trace with the live Metal preview")
    args = parser.parse_args()
    environment = dict(os.environ, DREAMS_RECORD_NATIVE_SETTINGS="1", DREAMS_NATIVE_TRACE_MODE="full")
    if args.metal:
        environment.update(DREAMS_NATIVE_CAPTURE_BACKEND="screen-capture-kit", DREAMS_NATIVE_TRACE_MODE="metal")
    with tempfile.TemporaryDirectory(prefix="dreams-native-feed-") as feed:
        environment["DREAMS_FEED_DIRECTORY"] = feed
        result = subprocess.run(
            ["zsh", "scripts/swift-macos.sh", "test", "-c", "release", "--filter", "recordNativeFormsWithScreener"], cwd=ROOT,
            env=environment,
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
    names = {frame["name"] for frame in frames}
    if args.metal:
        expected = {"metal.rain.playing", "metal.rain.paused", "metal.rain.resumed", "metal.appearance"}
        assert len(frames) == 4 and names == expected, "Incomplete Metal trace"
        assert all(record.get("metadata", {}).get("capture.backend") == "ScreenCaptureKit.window" for record in frames)
        markers = {record["name"]: record for record in records if record["kind"] == "marker"}
        assert markers["metal.rain.paused"]["metadata"]["previewPlaying"] == "false"
        assert markers["metal.rain.resumed"]["metadata"]["previewPlaying"] == "true"
        assert all((trace / record["blob"]).is_file() for record in frames)
        print(f"PASS: complete Screener Metal trace, {len(frames)} compositor frames: {trace}")
        return
    assert len(frames) == 35
    assert {"appearance.preset.classic", "appearance.preset.dimmed", "appearance.preset.monochrome",
            "appearance.palette.blue", "appearance.palette.narrow", "appearance.custom"} <= names
    for section in ("general", "appearance", "rain", "background", "words", "displays", "advanced"):
        assert f"section.{section}" in names, f"Missing wide {section} checkpoint"
        assert f"section.{section}.narrow" in names, f"Missing narrow {section} checkpoint"
    assert {"appearance.large-text.narrow", "rain.large-text.narrow"} <= names
    assert {"rain.edited.light", "rain.minimum.light", "rain.minimum.dark"} <= names
    assert {"rain.expanded.light", "rain.expanded.dark"} <= names
    assert all((trace / record["blob"]).is_file() for record in frames)
    backend = os.environ.get("DREAMS_NATIVE_CAPTURE_BACKEND", "hierarchy")
    print(f"PASS: complete Screener native settings trace, {len(frames)} {backend} frames: {trace}")


if __name__ == "__main__":
    main()
