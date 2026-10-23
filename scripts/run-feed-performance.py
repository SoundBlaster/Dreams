#!/usr/bin/env python3
"""Publish a fixed synthetic mailbox trace outside the rendering process."""
import argparse
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import selectors
import subprocess
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
APPLE_EPOCH = 978307200


def host_time():
    # Python <3.10 monotonic() uses a process-relative epoch on macOS.
    # UPTIME_RAW exposes the mach_absolute_time domain shared with Core Animation.
    return time.clock_gettime(time.CLOCK_UPTIME_RAW)


def load_module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_trace(trace, seconds):
    events = trace["events"]
    if not 1 <= trace["sessions"] <= 24 or not 0 <= trace["expiredFiles"] <= 24:
        raise ValueError("Bounded synthetic session counts required")
    if not 1 <= len(events) <= trace["sessions"]:
        raise ValueError("One unique event per session, at most 24 events")
    offsets = [e["offset"] for e in events]
    if offsets != sorted(set(offsets)) or not all(0 <= t <= seconds - 5 for t in offsets):
        raise ValueError("Ordered unique event offsets must leave five seconds for delivery")
    if not 0 <= trace["expiryOffset"] <= seconds - 5:
        raise ValueError("Expiry offset is outside collection")
    if not all(e["label"].strip() and len(e["label"]) <= 120 for e in events):
        raise ValueError("Use bounded nonempty synthetic labels")


def write_message(directory, session, event=None, expired=False):
    started = host_time()
    with (directory / ".lock").open("a+b") as lock:
        while True:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if host_time() - started > 2:
                    raise TimeoutError("Synthetic writer lock timeout") from None
                time.sleep(.005)
        now = time.time() - APPLE_EPOCH
        message = {"sessionID": session, "words": ["AGENT"], "color": "cyan", "activity": "working",
                   "updatedAt": now, "expiresAt": now - 1 if expired else now + 300,
                   "actionScore": 1, "events": [] if event is None else [
                       {"id": event["id"], "time": now, "label": event["label"]}]}
        path = directory / (hashlib.sha256(session.encode()).hexdigest() + ".json")
        temporary = directory / ".synthetic-publish"
        temporary.write_text(json.dumps(message, ensure_ascii=False))
        temporary.chmod(0o600)
        commit_began = host_time()
        os.replace(temporary, path)
        committed = host_time()
    return {"began": started, "commitBegan": commit_began, "committed": committed,
            "sessionID": session, "eventID": None if event is None else event["id"]}


def execute(command, env, mailbox, scenario, trace, log):
    process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    writes = []
    try:
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        if not selector.select(timeout=60):
            raise ValueError("No startup clock handshake")
        line = process.stdout.readline()
        log.write(line)
        if not line.startswith("PERFORMANCE_STARTED="):
            raise ValueError("Invalid startup handshake: " + line)
        began = float(line.split("=", 1)[1])
        received = host_time()
        if not 0 <= received - began <= 5:
            raise ValueError(f"Runner/app host clocks are not comparable: app={began}, runner={received}, delta={received - began}")
        for index in range(trace["sessions"]):
            writes.append(write_message(mailbox, f"synthetic-{index:02}"))
        schedule = [(e["offset"], "event", i, e) for i, e in enumerate(trace["events"])]
        schedule.append((trace["expiryOffset"], "expiry", 0, None))
        for offset, kind, index, event in sorted(schedule):
            target = began + scenario["warmupSeconds"] + offset
            time.sleep(max(0, target - host_time()))
            if process.poll() is not None:
                raise ValueError("App exited before trace completed")
            if kind == "event":
                identity = str(uuid.uuid5(uuid.NAMESPACE_URL, f"dreams-feed/{trace['name']}/{index}"))
                writes.append(write_message(mailbox, f"synthetic-{index:02}", event | {"id": identity})
                              | {"scheduled": target, "label": event["label"]})
            else:
                for expired in range(trace["expiredFiles"]):
                    writes.append(write_message(mailbox, f"expired-{expired:02}", expired=True))
        remaining = began + scenario["warmupSeconds"] + scenario["measureSeconds"] - host_time()
        tail, _ = process.communicate(timeout=max(0, remaining) + 30)
        log.write(tail)
        leftovers = len(list(mailbox.glob("*.json")))
        return {"exitCode": process.returncode, "started": began, "handshakeReceived": received,
                "clock": {"implementation": "clock_gettime(CLOCK_UPTIME_RAW)",
                          "resolution": time.clock_getres(time.CLOCK_UPTIME_RAW)}, "writes": writes,
                "remainingJSONFiles": leftovers}
    except Exception as error:
        log.write(f"RUNNER_ERROR={error}\n")
        return {"exitCode": 1, "error": str(error), "writes": writes,
                "remainingJSONFiles": len(list(mailbox.glob("*.json")))}
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=ROOT / "dist/Dreams.app/Contents/MacOS/Dreams")
    parser.add_argument("--scenario", type=Path, default=ROOT / "research/performance/scenarios/dense.json")
    parser.add_argument("--trace", type=Path, default=ROOT / "research/performance/feed-trace.json")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--smoke", action="store_true", help="1s warmup + 12s, two events; not baseline")
    args = parser.parse_args()
    if not 1 <= args.runs <= 10:
        parser.error("--runs must be 1...10")
    scenario = json.loads(args.scenario.read_text())
    trace = json.loads(args.trace.read_text())
    if args.smoke:
        scenario.update(warmupSeconds=1, measureSeconds=12)
        trace.update(events=[{"offset": 0.2, "label": "TRACE"}, {"offset": 4.5, "label": "ПРОБА"}], expiryOffset=6)
    validate_trace(trace, scenario["measureSeconds"])
    args.output.mkdir(parents=True, exist_ok=False)
    fixture = args.output.resolve() / "scenario.json"
    fixture.write_text(json.dumps(scenario, indent=2) + "\n")
    trace_path = args.output / "trace.json"
    trace_path.write_text(json.dumps(trace, indent=2, ensure_ascii=False) + "\n")
    common = load_module("performance", "run-performance.py")
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    resources = args.binary.parent.parent / "Resources/Dreams_Dreams.bundle"
    if (resources / "Contents/Resources").is_dir():
        resources = resources / "Contents/Resources"
    manifest = {"schemaVersion": 3, "runKind": "smoke" if args.smoke else "feed-baseline",
                "revision": revision, "binarySHA256": common.digest(args.binary),
                "workingTreeStatus": subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True),
                "fixtureSHA256": common.digest(fixture), "traceSHA256": common.digest(trace_path),
                "resourceSHA256": {n: common.digest(resources / n) for n in ["Rain.metal", "DreamsMatrix.ttf", "Matrix-Code.ttf"]},
                "hardwareModel": subprocess.check_output(["sysctl", "-n", "hw.model"], text=True).strip(),
                "cpuModel": subprocess.check_output(["sysctl", "-n", "machdep.cpu.brand_string"], text=True).strip(),
                "toolchain": subprocess.check_output(["swift", "--version"], text=True).strip(),
                "python": __import__("sys").version,
                "sdk": subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-version"], text=True).strip(), "results": []}
    for run in range(1, args.runs + 1):
        report = args.output.resolve() / f"run-{run:02}.json"
        command = [str(args.binary.resolve()), "--performance-feed", str(fixture), str(report)]
        with tempfile.TemporaryDirectory(prefix="dreams-feed-probe-") as temporary:
            env = os.environ | {"DREAMS_FEED_DIRECTORY": temporary, "DREAMS_PERF_REVISION": revision}
            with (args.output / f"run-{run:02}.log").open("w") as log:
                publication = execute(command, env, Path(temporary), scenario, trace, log)
        (args.output / f"publish-{run:02}.json").write_text(json.dumps(publication, indent=2) + "\n")
        data = json.loads(report.read_text()) if report.exists() else {}
        valid = publication["exitCode"] == 0 and data.get("valid", False) and data.get("feedProbe", False)
        manifest["results"].append({"file": report.name, "publication": f"publish-{run:02}.json",
                                    "command": command, "exitCode": publication["exitCode"], "valid": valid})
        (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"feed {run}/{args.runs}: frame-valid={valid}", flush=True)
        if not valid:
            raise SystemExit("Invalid run retained")


if __name__ == "__main__":
    main()
