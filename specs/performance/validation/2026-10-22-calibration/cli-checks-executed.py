import json,os,subprocess,tempfile
from pathlib import Path
root=Path('/Volumes/TB5/Developer/Builds/GitHub/Dreams-4b967f9f500c9508/performance')
rows=[]
with tempfile.TemporaryDirectory(dir=root,prefix='cli-guards-') as folder:
    dest=Path(folder);feed=dest/'feed';feed.mkdir();out=dest/'out.json'
    binary=str(Path('dist/Dreams.app/Contents/MacOS/Dreams').resolve())
    fixture=str(Path('research/performance/scenarios/dense.json').resolve())
    env=os.environ|{'DREAMS_FEED_DIRECTORY':str(feed),'DREAMS_PERF_REVISION':'bb400f40a3ee9b950d91c65a19238b78b00108ec'}
    for name,args in [('missing-mode',['--performance-calibration',fixture,str(out)]),('invalid-mode',['--performance-calibration',fixture,str(out),'invalid']),('ambiguous-flags',['--performance-run','--performance-calibration',fixture,str(out),'control'])]:
        child=subprocess.run([binary,*args],env=env,capture_output=True,text=True,timeout=10)
        rows.append(dict(case=name,exitCode=child.returncode,output=child.stdout+child.stderr,reportCreated=out.exists()))
        assert child.returncode==1 and not out.exists(),rows[-1]
    out.write_text('preserve me')
    child=subprocess.run([binary,'--performance-calibration',fixture,str(out),'control'],env=env,capture_output=True,text=True,timeout=10)
    rows.append(dict(case='existing-output',exitCode=child.returncode,output=child.stdout+child.stderr,preserved=out.read_text()=='preserve me'))
    assert child.returncode==1 and rows[-1]['preserved']
Path('/tmp/dreams-calibration-cli-results.json').write_text(json.dumps(rows,indent=2)+'\n')
print('PASS: missing/invalid/ambiguous calibration modes and existing-output refusal')
