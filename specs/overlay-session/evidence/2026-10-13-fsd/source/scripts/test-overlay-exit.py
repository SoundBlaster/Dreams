#!/usr/bin/env python3
"""Opt-in native exit checks with a temporary monitor and an isolated hook feed."""
import json
import os
from pathlib import Path
import plistlib
import shutil
import signal
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

subprocess.run(["swift", "test", "list", "-c", "release"], cwd=ROOT, check=True)
binary = Path(subprocess.check_output(["swift", "build", "-c", "release", "--show-bin-path"], cwd=ROOT, text=True).strip())
toolchain = Path(subprocess.check_output(["xcrun", "--find", "swift"], text=True).strip()).parent.parent
developer = toolchain.parents[2]
helper = toolchain / "libexec/swift/pm/swiftpm-testing-helper"
bundle = binary / "DreamsTests.xctest/Contents/MacOS/DreamsTests"
# A command-line test helper cannot become active. Give it a distinct app identity
# so the WindowServer focus assertions exercise the same lifecycle as Dreams.
with tempfile.TemporaryDirectory(prefix="dreams-exit-") as temporary:
    directory = Path(temporary)
    app = directory / "DreamsExitTests.app"
    executable = app / "Contents/MacOS/ExitTests"
    executable.parent.mkdir(parents=True)
    shutil.copy2(helper, executable)
    resources = app / "Contents/Resources"
    resources.mkdir()
    shutil.copytree(binary / "Dreams_Dreams.bundle", resources / "Dreams_Dreams.bundle")
    (app / "Contents/Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "ru.egormerkushev.dreams.exit-test-runner", "CFBundleExecutable": "ExitTests",
        "CFBundleName": "Dreams Exit Tests", "CFBundlePackageType": "APPL", "NSPrincipalClass": "NSApplication",
    }))
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(app)], check=True, capture_output=True)
    stdout = directory / "stdout.log"
    stderr = directory / "stderr.log"
    environment = {
        "DREAMS_TEST_EXIT": "1", "DREAMS_FEED_DIRECTORY": str(directory / "feed"), "DREAMS_LANGUAGE": "en",
        "DYLD_FRAMEWORK_PATH": str(developer / "Platforms/MacOSX.platform/Developer/Library/Frameworks"),
        "DYLD_LIBRARY_PATH": str(developer / "Platforms/MacOSX.platform/Developer/usr/lib"),
    }
    command = ["open", "-W", "-n", "--stdout", str(stdout), "--stderr", str(stderr)]
    for key, value in environment.items():
        command.extend(["--env", f"{key}={value}"])
    command.extend([str(app), "--args", "--test-bundle-path", str(bundle), "-c", "release",
                    "--filter", "OverlayExitTests", str(bundle), "--testing-library", "swift-testing"])
    process = subprocess.Popen(
        command, cwd=ROOT,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True,
    )
    try:
        output, _ = process.communicate(timeout=120)
    except subprocess.TimeoutExpired:
        for line in subprocess.check_output(["ps", "-Ao", "pid=,args="], text=True).splitlines():
            pid, arguments = line.strip().split(None, 1)
            if arguments.startswith(str(executable) + " "):
                os.kill(int(pid), signal.SIGKILL)
        os.killpg(process.pid, signal.SIGKILL)
        output, _ = process.communicate()
        print(output, end="", flush=True)
        raise
    output += stdout.read_text() + stderr.read_text()
print(output, end="", flush=True)
assert process.returncode == 0, f"Exit checks failed: {process.returncode}"
assert "recorded an issue" not in output, "Swift Testing reported a failed assertion"
paths = [line.removeprefix("DREAMS_EXIT_TRACE=") for line in output.splitlines()
         if line.startswith("DREAMS_EXIT_TRACE=")]
assert len(paths) == 1, "Runner exited without completing the exit scenario"
trace = Path(paths[0])
records = [json.loads(line) for line in (trace / "timeline.jsonl").read_text().splitlines()]
assert records[-1]["kind"] == "sessionEnded"
assert not any(record.get("name") == "Scenario.failed" for record in records)
frames = [record for record in records if record["kind"] == "keyframe"]
assert len(frames) == 4
assert all((trace / frame["blob"]).is_file() for frame in frames)
print(f"PASS: exit lifecycle and four Screener checkpoints; trace: {trace}")
