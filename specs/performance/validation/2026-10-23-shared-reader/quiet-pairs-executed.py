from pathlib import Path
import os, subprocess, json
root=Path('/Users/egor/.codex/worktrees/performance-baseline/Dreams')
external=Path('/Volumes/TB5/Developer/Builds/GitHub/Dreams-4b967f9f500c9508/performance')
output=external/'shared-reader-quiet-pairs-2026-10-23'
output.mkdir(exist_ok=False)
suite={'kind':'two-supplemental-quiet-pairs','note':'Diagnostic after three long intervals in primary series; not pooled into the preregistered five pairs. No other agent file/build/test/UI work during collection. Interactive OS background load remains uncontrolled.','runs':[]}
for pair in [1,2]:
 for variant in (['before','after'] if pair==1 else ['after','before']):
  binary=external/'feed-before-29e07ea/Dreams.app/Contents/MacOS/Dreams' if variant=='before' else root/'dist/Dreams.app/Contents/MacOS/Dreams'
  revision='29e07eac9ed6f98844bac9e74031cd3be62560ab' if variant=='before' else '680833b15edb0435c31bf3f4f1bc3c17ca934dd5'
  directory=output/f'{pair:02}-{variant}'
  command=['python3',str(root/'scripts/run-feed-performance.py'),'--binary',str(binary),'--revision',revision,'--output',str(directory),'--runs','1']
  result=subprocess.run(command,cwd=root,timeout=150)
  suite['runs'].append({'pair':pair,'variant':variant,'directory':directory.name,'command':command,'exitCode':result.returncode})
  (output/'suite.json').write_text(json.dumps(suite,indent=2)+'\n')
  print(f'quiet pair {pair}/2 {variant}: exit={result.returncode}',flush=True)
  if result.returncode: raise SystemExit(result.returncode)
