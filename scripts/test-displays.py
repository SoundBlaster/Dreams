#!/usr/bin/env python3
"""Opt-in native display checks; reject a runner that exits before completing the scenario."""
import json
import os
from pathlib import Path
import subprocess
import selectors
import shutil
import time

from smoke import MCPClient
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def record_settings():
    with tempfile.TemporaryDirectory(prefix="dreams-displays-") as feed:
        result = subprocess.run(
            ["swift", "test", "-c", "release", "--filter", "DisplaySettingsTraceTests"],
            cwd=ROOT, env=dict(os.environ, DREAMS_TEST_DISPLAYS="1", DREAMS_FEED_DIRECTORY=feed),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180,
        )
    print(result.stdout, end="", flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
    paths = [line.removeprefix("DREAMS_DISPLAY_TRACE=") for line in result.stdout.splitlines()
             if line.startswith("DREAMS_DISPLAY_TRACE=")]
    assert len(paths) == 1, "Runner exited without completing the display scenario"
    trace = Path(paths[0])
    records = [json.loads(line) for line in (trace / "timeline.jsonl").read_text().splitlines()]
    assert records[-1]["kind"] == "sessionEnded", "Screener session did not close"
    assert not any(r.get("name") == "Scenario.failed" for r in records)
    frames = [r for r in records if r["kind"] == "keyframe"]
    assert len(frames) == 5, f"Expected five display checkpoints, got {len(frames)}"
    assert all((trace / frame["blob"]).is_file() for frame in frames)
    print(f"PASS: native settings actions and persistence; Screener trace: {trace}")



def build_fixture(directory):
    binary_dir = Path(subprocess.check_output(
        ["swift", "build", "-c", "release", "--show-bin-path"], cwd=ROOT, text=True).strip())
    app = directory / "DreamsDisplayTest.app"
    executable = app / "Contents/MacOS/Dreams"
    resources = app / "Contents/Resources"
    executable.parent.mkdir(parents=True)
    resources.mkdir()
    shutil.copy2(binary_dir / "Dreams", executable)
    shutil.copytree(binary_dir / "Dreams_Dreams.bundle", resources / "Dreams_Dreams.bundle")
    info = (ROOT / "scripts/Info.plist.in").read_text().replace("__VERSION__", (ROOT / "VERSION").read_text().strip())
    info = info.replace("ru.egormerkushev.dreams", "ru.egormerkushev.dreams.display-runtime-tests")
    (app / "Contents/Info.plist").write_text(info)
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(app)], check=True, capture_output=True)
    bridge = directory / "bridge.o"
    include = ROOT / "Sources/VirtualDisplayBridge/include"
    subprocess.run(["clang", "-fobjc-arc", "-c", str(ROOT / "Sources/VirtualDisplayBridge/VirtualDisplayBridge.m"),
                    "-I", str(include), "-o", str(bridge)], check=True)
    host = directory / "display-host"
    subprocess.run(["swiftc", "-swift-version", "6", "-parse-as-library", "-import-objc-header",
                    str(include / "VirtualDisplayBridge.h"), str(ROOT / "scripts/test-display-host.swift"),
                    str(bridge), "-framework", "CoreGraphics", "-o", str(host)], check=True)
    return executable, host


def initialize(client):
    client.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                  "clientInfo": {"name": "display-checks", "version": "1"}})
    client.send({"jsonrpc": "2.0", "method": "notifications/initialized"})


def wait_for(client, predicate):
    deadline = time.monotonic() + 10
    while True:
        state = client.call("dreams_status")
        if predicate(state):
            return state
        assert time.monotonic() < deadline, state
        time.sleep(0.15)


def live_displays():
    with tempfile.TemporaryDirectory(prefix="dreams-display-runtime-") as temporary:
        directory = Path(temporary)
        executable, host_binary = build_fixture(directory)
        feed = directory / "feed"
        feed.mkdir()
        env = dict(os.environ, DREAMS_FEED_DIRECTORY=str(feed), DREAMS_LANGUAGE="en")
        client = MCPClient(env=env, executable=executable, extra_args=("-rainDisplayMode", "all"))
        host = None
        selected = None
        try:
            initialize(client)
            initial = client.call("dreams_start", {"duration_seconds": 90})
            assert initial["display_mode"] == "all" and initial["rain_visible"], initial
            original = {w["display_uuid"]: w["window_number"] for w in initial["rain_windows"]}
            deadline = initial["expires_at"]
            host = subprocess.Popen([str(host_binary)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            with selectors.DefaultSelector() as selector:
                selector.register(host.stdout, selectors.EVENT_READ)
                assert selector.select(timeout=10), "Virtual display host did not become ready"
                ready = json.loads(host.stdout.readline())
            display_id = ready["display_id"]
            added = wait_for(client, lambda s: len(s["rain_windows"]) == len(original) + 1
                             and all(w["frames_rendered"] > 0 for w in s["rain_windows"]))
            extra = next(d for d in added["displays"] if d["id"] == display_id)
            assert all(any(w["display_uuid"] == uuid and w["window_number"] == number
                           for w in added["rain_windows"]) for uuid, number in original.items()), added
            assert added["expires_at"] == deadline, added
            selected = MCPClient(env=env, executable=executable, extra_args=(
                "-rainDisplayMode", "selected", "-rainDisplayIDs", f'("{extra["uuid"]}")'))
            initialize(selected)
            subset = selected.call("dreams_start", {"duration_seconds": 90})
            assert subset["selected_display_ids"] == [extra["uuid"]], subset
            assert [w["display_id"] for w in subset["rain_windows"]] == [display_id], subset
            host.stdin.close()
            host.wait(timeout=8)
            disconnected = wait_for(client, lambda s: len(s["rain_windows"]) == len(original)
                                    and all(d["id"] != display_id for d in s["displays"]))
            assert disconnected["expires_at"] == deadline, disconnected
            assert {w["display_uuid"]: w["window_number"] for w in disconnected["rain_windows"]} == original, disconnected
            fallback = wait_for(selected, lambda s: s["rain_visible"] and all(
                w["display_id"] != display_id for w in s["rain_windows"]))
            assert fallback["selected_display_ids"] == [extra["uuid"]], fallback
            selected.close()
            selected = None
            workspace = client.call("dreams_workspace_create")
            workspace_id = workspace["virtual_display_id"]
            assert workspace_id is not None, workspace
            assert not any(w["display_id"] == workspace_id for w in workspace["rain_windows"]), workspace
            assert next(d for d in workspace["displays"] if d["id"] == workspace_id)["excluded"], workspace
            stopped = client.call("dreams_prepare_ui")
            assert not stopped["rain_windows"] and not stopped["rain_visible"] and not stopped["prevents_idle_sleep"], stopped
            assert client.call("dreams_resume")["rain_visible"]
            client.call("dreams_start", {"duration_seconds": 1})
            expired = wait_for(client, lambda s: s["last_stop_reason"] == "timer")
            assert not expired["rain_windows"] and not expired["prevents_idle_sleep"], expired
            print("PASS: real MCP process, two rendered displays, live hot-plug, retained windows/timer, subset, unplug fallback, workspace exclusion and global stop/expiry")
        finally:
            try:
                if selected is not None:
                    selected.close()
            finally:
                try:
                    client.close()
                finally:
                    stop_host(host)


def stop_host(host):
    if host is None:
        return
    if not host.stdin.closed:
        host.stdin.close()
    try:
        host.wait(timeout=8)
    except subprocess.TimeoutExpired:
        host.kill()
        host.wait(timeout=3)
    host.stdout.close()
    errors = host.stderr.read().decode()
    host.stderr.close()
    assert not errors, errors


def main():
    record_settings()
    live_displays()


if __name__ == "__main__":
    main()
