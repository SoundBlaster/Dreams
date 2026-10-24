#!/usr/bin/env python3
"""Join target-only native command/GPU intervals with the opt-in application report."""
import argparse
from bisect import bisect_right
from collections import defaultdict
import json
import gzip
from pathlib import Path
from xml.etree import ElementTree as ET


def read_json(path):
    if path.exists():
        return json.loads(path.read_text())
    return json.loads(gzip.decompress(path.with_suffix(path.suffix + '.gz').read_bytes()))


def read_table(folder, name):
    if (folder / 'native-input.json.gz').exists():
        return read_json(folder / 'native-input.json')['tables'][name]
    tree = ET.parse(folder / (name + '.xml'))
    ids = {e.get('id'): e for e in tree.iter() if e.get('id')}

    def resolve(element):
        while element.get('ref'):
            element = ids[element.get('ref')]
        return element

    def value(element):
        element = resolve(element)
        if element.tag == 'sentinel':
            return None
        if element.tag == 'process':
            return int(resolve(element.find('pid')).text)
        try:
            return int(element.text)
        except (ValueError, TypeError):
            return element.get('fmt', element.text)

    columns = [c.findtext('mnemonic') for c in tree.findall('.//schema/col')]
    return [{key: value(e) for key, e in zip(columns, row)} for row in tree.iter('row')]


def analyze(folder):
    report = read_json(folder / 'run-01.json')
    manifest = read_json(folder / 'manifest.json')
    pid = manifest['pid']
    if (folder / 'native-input.json.gz').exists():
        clock = read_json(folder / 'native-input.json')['clock']
        numerator, denominator = clock['numerator'], clock['denominator']
        epoch = clock['machAbsoluteEpoch'] * numerator / denominator / 1e9
    else:
        tree = ET.parse(folder / 'time-info.xml')
        row = tree.find('.//row')
        timebase = row.find('mach-timebase-info')
        numerator, denominator = [int(e.text) for e in timebase.findall('mach-timebase-info-field')]
        epoch = int(row.find('mach-absolute-time').text) * numerator / denominator / 1e9
    samples = report['samples']
    begins = [s['submittedAt'] for s in samples]
    gpu_by_buffer = defaultdict(list)
    for interval in read_table(folder, 'metal-gpu-intervals'):
        if interval['process'] == pid:
            gpu_by_buffer[interval['cmdbuffer-id']].append(interval)
    completed = {r['cmdbuffer-id']: r['timestamp'] / 1e9 + epoch
                 for r in read_table(folder, 'metal-command-buffer-completed')}
    commands = [r for r in read_table(folder, 'metal-application-command-buffer-submissions')
                if r['process'] == pid]
    frames = []
    unmatched = []
    for command in commands:
        created = epoch + command['start'] / 1e9
        index = bisect_right(begins, created) - 1
        if index < 0:
            unmatched.append(command['cmdbuffer-id'])
            continue
        sample = samples[index]
        intervals = gpu_by_buffer[command['cmdbuffer-id']]
        if not intervals or created > sample['submittedAt'] + sample['drawSeconds'] + 0.0005:
            unmatched.append(command['cmdbuffer-id'])
            continue
        commit = created + command['duration'] / 1e9
        gpu_start = epoch + min(r['start'] for r in intervals) / 1e9
        gpu_end = epoch + max(r['start'] + r['duration'] for r in intervals) / 1e9
        gpu_span = gpu_end - gpu_start
        frames.append({'frame': sample['id'], 'commandBufferID': command['cmdbuffer-id'],
                       'creationAt': created, 'committedAt': commit,
                       'gpuStartedAt': gpu_start, 'gpuEndedAt': gpu_end,
                       'completionObservedAt': completed.get(command['cmdbuffer-id']),
                       'presentedAt': sample['presentedAt'],
                       'presentationIntervalMs': (sample['presentedAt'] - samples[index - 1]['presentedAt']) * 1000,
                       'drawMs': sample['drawSeconds'] * 1000,
                       'commitToGpuStartMs': (gpu_start - commit) * 1000,
                       'gpuSpanMs': gpu_span * 1000,
                       'reportedGpuMs': sample['gpuSeconds'] * 1000,
                       'gpuSpanDifferenceMs': abs(gpu_span - sample['gpuSeconds']) * 1000,
                       'gpuEndToPresentedMs': (sample['presentedAt'] - gpu_end) * 1000,
                       'readAttemptsWithin50msOfDraw': sum(abs(r['began'] - sample['submittedAt']) < 0.05
                                                         for r in report.get('feedReads', []))})
    gaps = [r for r in frames if r['presentationIntervalMs'] > 50]
    all_gaps = [b['id'] for a, b in zip(samples, samples[1:]) if b['presentedAt'] - a['presentedAt'] > 0.05]
    assert len({r['frame'] for r in frames}) == len(frames), 'Ambiguous native/application frame match'
    return {'runtimeRevision': manifest['runtimeRevision'], 'binarySHA256': manifest['binarySHA256'],
            'targetPID': pid, 'traceEpochSeconds': epoch,
            'timebase': {'numerator': numerator, 'denominator': denominator},
            'nativeCommandCount': len(commands), 'matchedFrameCount': len(frames),
            'unmatchedCommandBuffers': unmatched, 'applicationGapFrames': all_gaps,
            'nativeCoveredGapFrames': [r['frame'] for r in gaps],
            'maxGpuSpanDifferenceMs': max(r['gpuSpanDifferenceMs'] for r in frames),
            'frames': frames, 'gaps': gaps,
            'limits': 'Instrumented target-only evidence. Frame join uses creation within the single-threaded draw interval, unique IDs and matching native/API GPU spans. Coverage uses actual exported records, not requested window length. PresentedTime is the existing drawable timestamp, not physical scanout. No reader causality or historical-gap attribution.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('export_directory', type=Path)
    args = parser.parse_args()
    print(json.dumps(analyze(args.export_directory), indent=2))
