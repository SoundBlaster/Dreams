import json, os, subprocess, tempfile
from pathlib import Path
root=Path('/Volumes/TB5/Developer/Builds/GitHub/Dreams-4b967f9f500c9508')
checks=['RainPerformanceTests','SearchOccupancyTests','DropHeadRenderingTests','GlyphPulseRenderingTests','TransparentFadeRenderingTests','RainTrailRenderingTests','previewIsAPixelExactScreenCrop']
results=[]
for index,name in enumerate(checks):
    log=Path(f'/tmp/dreams-perf-guards-test-{index+1:02}.log')
    with tempfile.TemporaryDirectory(prefix='dreams-perf-tests-') as feed, log.open('w') as stream:
        env=os.environ | {'DREAMS_SWIFT_SCRATCH_PATH':str(root/'swiftpm'),'DREAMS_SWIFT_CACHE_PATH':'/Volumes/TB5/Developer/Caches/swiftpm','DREAMS_TEST_METAL':'1','DREAMS_FEED_DIRECTORY':feed}
        child=subprocess.run(['zsh','scripts/swift-macos.sh','test','-c','release','--filter',name],env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=180)
    results.append(dict(filter=name,exitCode=child.returncode,log=log.name))
    print(name,child.returncode,flush=True)
    Path('/tmp/dreams-perf-guards-tests.json').write_text(json.dumps(results,indent=2)+'\n')
    if child.returncode: raise SystemExit(child.returncode)
