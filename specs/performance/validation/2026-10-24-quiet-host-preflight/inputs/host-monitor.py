#!/usr/bin/env python3
"""Experiment-only Darwin sidecar; no arguments, paths or environment from other processes are exported."""
import argparse
import ctypes
import json
import os
from pathlib import Path
import re
import resource
import signal
import subprocess
import time

BUILD = {"rustc", "cargo", "rustdoc", "swift", "swiftc", "swift-frontend", "swift-build", "swift-test", "xcodebuild", "clang", "clang++", "ld", "ld-prime", "lld", "ninja", "make", "cmake"}
SYSTEM = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
SYSTEM.mach_host_self.restype = ctypes.c_uint
SYSTEM.host_statistics.argtypes = [ctypes.c_uint, ctypes.c_int, ctypes.POINTER(ctypes.c_uint), ctypes.POINTER(ctypes.c_uint)]
SYSTEM.host_statistics.restype = ctypes.c_int
HOST = SYSTEM.mach_host_self()
STOP = False


def host_time():
    return time.clock_gettime(time.CLOCK_UPTIME_RAW)


def process_seconds(value):
    days, clock = value.split("-", 1) if "-" in value else ("0", value)
    fields = [float(x) for x in clock.split(":")]
    return int(days) * 86400 + sum(x * 60 ** i for i, x in enumerate(reversed(fields)))


def cpu_ticks():
    ticks = (ctypes.c_uint * 4)()
    count = ctypes.c_uint(4)
    if SYSTEM.host_statistics(HOST, 3, ticks, ctypes.byref(count)) != 0 or count.value != 4:
        raise RuntimeError("HOST_CPU_LOAD_INFO unavailable")
    return list(ticks)


def processes():
    output = subprocess.check_output(["/bin/ps", "-Ao", "pid=,time=,comm="], text=True)
    result = {}
    for line in output.splitlines():
        pid, elapsed, executable = line.split(None, 2)
        result[int(pid)] = (process_seconds(elapsed), executable.rsplit("/", 1)[-1])
    return result


def memory():
    output = subprocess.check_output(["/usr/sbin/sysctl", "-n", "kern.memorystatus_vm_pressure_level", "vm.swapusage"], text=True).splitlines()
    match = re.search(r"used = ([0-9.]+)M", output[1])
    if not match:
        raise RuntimeError("Unrecognized swap usage")
    vm = subprocess.check_output(["/usr/bin/vm_stat"], text=True)
    swapouts = re.search(r"^Swapouts:\s+(\d+)\.", vm, re.M)
    if not swapouts:
        raise RuntimeError("Swapouts unavailable")
    return {"pressureLevel": int(output[0]), "swapUsedMiB": float(match[1]), "swapoutPages": int(swapouts[1])}


def own_cpu():
    values = [resource.getrusage(resource.RUSAGE_SELF), resource.getrusage(resource.RUSAGE_CHILDREN)]
    return sum(v.ru_utime + v.ru_stime for v in values)


def collect(seconds, full):
    started = host_time()
    cpu_started = own_cpu()
    rows = []
    previous = None
    while not STOP and host_time() - started < seconds:
        began = host_time()
        if full:
            ticks = cpu_ticks()
            snapshot = processes()
            taken = host_time()
            row = {"at": taken, "sampleCallMs": (taken - began) * 1000, "ticks": ticks}
            if previous is not None:
                dt = taken - previous["at"]
                delta = [(a-b) & 0xffffffff for a, b in zip(ticks, previous["ticks"])]
                if not 0 < dt < 10 or not sum(delta):
                    raise RuntimeError("Invalid sampling interval/counters")
                busy = (sum(delta) - delta[2]) / sum(delta) * os.cpu_count()
                rain = build = 0.0
                active_build = []
                for pid, (cpu, name) in snapshot.items():
                    if pid not in previous["processes"]:
                        continue  # Short/new/exited process work remains in aggregate host ticks.
                    old_cpu, old_name = previous["processes"][pid]
                    if name != old_name or cpu < old_cpu:
                        continue
                    cores = (cpu - old_cpu) / dt
                    if name == "Dreams":
                        rain += cores
                    if name in BUILD:
                        build += cores
                        if cores >= .1:
                            active_build.append({"tool": name, "cores": cores})
                row.update(intervalSeconds=dt, hostBusyCores=busy, dreamsCores=rain,
                           externalBusyEstimateCores=busy-rain, buildCores=build,
                           activeBuild=active_build, dreamsProcesses=sum(n == "Dreams" for _, n in snapshot.values()))
            if not rows or len(rows) % 5 == 0:
                row["memory"] = memory()
                row["power"] = "AC" if "AC Power" in subprocess.check_output(["/usr/bin/pmset", "-g", "batt"], text=True) else "battery"
            rows.append(row)
            previous = {"at": taken, "ticks": ticks, "processes": snapshot}
        target = started + (int(host_time() - started) + 1)
        time.sleep(max(0, target-host_time()))
    ended = host_time()
    return {"clock": "clock_gettime(CLOCK_UPTIME_RAW)", "full": full, "started": started,
            "ended": ended, "cpuSecondsSelfAndChildren": own_cpu()-cpu_started,
            "cpuScope": "Sidecar plus sampled command children; control excludes ps/sysctl/vm_stat/pmset calls. Not renderer-latency calibration.",
            "intervalSeconds": 1, "cpuCount": os.cpu_count(), "samples": rows,
            "limits": "1 Hz aggregate ticks can miss short build-tool identity. Per-process delta excludes processes absent at either snapshot; external estimate may be signed/noisy. No scheduler/GPU attribution, frequency, energy or physical scanout observation."}


def stop(signum, frame):
    global STOP
    STOP = True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=int, required=True)
    parser.add_argument("--control", action="store_true")
    args = parser.parse_args()
    if not 1 <= args.seconds <= 900:
        parser.error("Bounded 1...900 seconds required")
    signal.signal(signal.SIGTERM, stop)
    args.output.write_text(json.dumps(collect(args.seconds, not args.control), indent=2)+"\n")
