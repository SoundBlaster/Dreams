#!/usr/bin/env python3
"""One bounded, instrumented feed diagnostic on an unchanged preserved executable."""
import argparse
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


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--binary', type=Path, required=True)
    parser.add_argument('--revision', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--template', default='Metal System Trace')
    args = parser.parse_args()
    args.output.mkdir(exist_ok=False, parents=True)
    spec = importlib.util.spec_from_file_location('feed', args.root / 'scripts/run-feed-performance.py')
    feed = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(feed)
    scenario = json.loads((args.root / 'research/performance/scenarios/dense.json').read_text())
    trace = json.loads((args.root / 'research/performance/feed-trace.json').read_text())
    feed.validate_trace(trace, scenario['measureSeconds'])
    fixture = args.output / 'scenario.json'
    fixture.write_text(json.dumps(scenario, indent=2) + '\n')
    (args.output / 'trace.json').write_text(json.dumps(trace, indent=2, ensure_ascii=False) + '\n')
    manifest = {'kind': 'instrumented-cadence-diagnostic', 'runtimeRevision': args.revision,
                'runnerRevision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=args.root, text=True).strip(),
                'binarySHA256': digest(args.binary), 'fixtureSHA256': digest(fixture),
                'traceSHA256': digest(args.output / 'trace.json'), 'template': args.template,
                'limits': 'Profiler overhead uncalibrated; not baseline, acceptance or raw-trace publication.'}
    command = [str(args.binary.resolve()), '--performance-feed', str(fixture), str(args.output / 'run-01.json')]
    manifest['command'] = command
    profiler = None
    writes = []
    with tempfile.TemporaryDirectory(prefix='dreams-cadence-feed-') as directory:
        mailbox = Path(directory)
        env = os.environ | {'DREAMS_FEED_DIRECTORY': directory, 'DREAMS_PERF_REVISION': args.revision}
        app = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        manifest['pid'] = app.pid
        try:
            selector = selectors.DefaultSelector()
            selector.register(app.stdout, selectors.EVENT_READ)
            if not selector.select(timeout=30):
                raise RuntimeError('No app startup handshake')
            line = app.stdout.readline()
            if not line.startswith('PERFORMANCE_STARTED='):
                raise RuntimeError('Unexpected startup: ' + line)
            began = float(line.split('=', 1)[1])
            assert 0 <= feed.host_time() - began < 5
            manifest['started'] = began
            profiler_command = ['xcrun', 'xctrace', 'record', '--template', args.template,
                                '--time-limit', '100s', '--window', '60s', '--output', str(args.output / 'recording.trace'),
                                '--attach', str(app.pid)]
            manifest['profilerCommand'] = profiler_command
            with (args.output / 'profiler.log').open('w') as log:
                profiler = subprocess.Popen(profiler_command, stdout=log, stderr=subprocess.STDOUT)
                for index in range(trace['sessions']):
                    writes.append(feed.write_message(mailbox, f'synthetic-{index:02}'))
                schedule = [(e['offset'], 'event', i, e) for i, e in enumerate(trace['events'])]
                schedule.append((trace['expiryOffset'], 'expiry', 0, None))
                for offset, kind, index, event in sorted(schedule):
                    target = began + scenario['warmupSeconds'] + offset
                    time.sleep(max(0, target - feed.host_time()))
                    if app.poll() is not None:
                        raise RuntimeError('App exited before trace completion')
                    if kind == 'event':
                        identity = str(uuid.uuid5(uuid.NAMESPACE_URL, f"dreams-feed/{trace['name']}/{index}"))
                        writes.append(feed.write_message(mailbox, f'synthetic-{index:02}', event | {'id': identity})
                                      | {'scheduled': target, 'label': event['label']})
                    else:
                        for expired in range(trace['expiredFiles']):
                            writes.append(feed.write_message(mailbox, f'expired-{expired:02}', expired=True))
                remaining = began + scenario['warmupSeconds'] + scenario['measureSeconds'] - feed.host_time()
                tail, _ = app.communicate(timeout=max(0, remaining) + 30)
                (args.output / 'app.log').write_text(line + tail)
                manifest['appExitCode'] = app.returncode
                manifest['remainingJSONFiles'] = len(list(mailbox.glob('*.json')))
                try:
                    manifest['profilerExitCode'] = profiler.wait(timeout=180)
                except subprocess.TimeoutExpired:
                    profiler.send_signal(2)
                    manifest['profilerExitCode'] = profiler.wait(timeout=20)
        except Exception as error:
            manifest['error'] = str(error)
        finally:
            if app.poll() is None:
                app.kill()
                app.wait()
            if profiler is not None and profiler.poll() is None:
                profiler.send_signal(2)
                try:
                    profiler.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    profiler.kill()
                    profiler.wait()
            manifest['writes'] = writes
            manifest['finished'] = feed.host_time()
            (args.output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({k: v for k, v in manifest.items() if k not in ['writes']}, indent=2), flush=True)


if __name__ == '__main__':
    main()
