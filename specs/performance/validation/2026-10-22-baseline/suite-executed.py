import json, subprocess, time
from pathlib import Path
root=Path('/Volumes/TB5/Developer/Builds/GitHub/Dreams-4b967f9f500c9508/performance/baseline-2026-10-22')
root.mkdir(exist_ok=False)
names=['normal','dense','dense-no-glow']
results=[]
for repeat in range(5):
    order=names[repeat%3:]+names[:repeat%3]
    for name in order:
        dest=root/f'{repeat+1:02}-{name}'
        print(f'START round={repeat+1} scenario={name}',flush=True)
        began=time.time()
        child=subprocess.run(['python3','scripts/run-performance.py','--scenario',f'research/performance/scenarios/{name}.json','--output',str(dest),'--runs','1'])
        results.append(dict(round=repeat+1,scenario=name,directory=dest.name,exitCode=child.returncode,beganUnix=began,endedUnix=time.time()))
        (root/'suite.json').write_text(json.dumps(dict(order='rotated across rounds; one renderer at a time',runs=results),indent=2)+'\n')
        if child.returncode:raise SystemExit(child.returncode)
print('SUITE_COMPLETE',flush=True)
