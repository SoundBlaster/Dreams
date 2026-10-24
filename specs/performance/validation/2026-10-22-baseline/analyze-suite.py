#!/usr/bin/env python3
"""Reproduce descriptive per-run statistics; no speedup gate or issue acceptance."""
import gzip
import json
from pathlib import Path
import statistics
import sys

def load(path):
    if path.exists(): return json.loads(path.read_text())
    return json.loads(gzip.decompress(Path(str(path)+'.gz').read_bytes()))

root=Path(sys.argv[1])
suite=load(root/'suite.json')
rows=[]
identities=set()
for entry in suite['runs']:
    folder=root/entry['directory']
    report=load(folder/'run-01.json')
    manifest=load(folder/'manifest.json')
    identities.add((manifest['revision'],manifest['binarySHA256']))
    samples=report['samples']
    times=sorted(s['presentedAt'] for s in samples if s.get('presentedAt') is not None)
    row=dict(round=entry['round'],scenario=entry['scenario'],valid=entry['exitCode']==0 and report['valid'],frames=len(samples),thermalStates=report['thermalStates'])
    for key in ['draw','simulation','instances','gpu']:
        value=report['summaries'][key+'_seconds'].get('p95')
        row[key+'P95ms']=None if value is None else value*1000
    value=report['summaries']['presentation_interval_seconds'].get('p99')
    row['presentationP99ms']=None if value is None else value*1000
    row['observedFPS']=(len(times)-1)/(times[-1]-times[0]) if len(times)>1 else None
    row['over50ms']=report['intervalsOver50ms'];row['over100ms']=report['intervalsOver100ms']
    rows.append(row)
groups={}
for name in ['normal','dense','dense-no-glow']:
    selected=[r for r in rows if r['scenario']==name]
    groups[name]=dict(count=len(selected))
    for key in ['drawP95ms','simulationP95ms','instancesP95ms','gpuP95ms','presentationP99ms','observedFPS']:
        values=[r[key] for r in selected if r[key] is not None]
        groups[name][key]=None if not values else dict(median=statistics.median(values),minimum=min(values),maximum=max(values))
paired=[]
for repeat in range(1,6):
    on=next((r for r in rows if r['round']==repeat and r['scenario']=='dense'),None)
    off=next((r for r in rows if r['round']==repeat and r['scenario']=='dense-no-glow'),None)
    if on and off and on['gpuP95ms'] and off['gpuP95ms'] is not None:
        paired.append(1-off['gpuP95ms']/on['gpuP95ms'])
result=dict(scope='macOS windowed1920x1080 production renderer; empty isolated feed; instrumentation overhead uncalibrated',complete=len(rows)==15 and all(r['valid'] for r in rows) and all(g['count']==5 for g in groups.values()),identities=[dict(revision=r,binarySHA256=b) for r,b in sorted(identities)],runs=rows,groups=groups,pairedGPUCostReduction=paired,limitations=['No fullscreen or tvOS acceptance','No allocator, memory, power or scripted agent traffic measurements','Glow0 is a diagnostic change of workload, not a shipped optimization','No numerical budget or automatic issue closure'])
print(json.dumps(result,indent=2))
