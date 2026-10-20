# Focus edge verification

Runtime d566578a16893d0804da883b8789aff7f26812b7; parent-built app installed on Apple TV4K1080p tvOS27 Simulator B29EC156-5EF9-4A56-8147-1C98D4E228DB. PID65264. No build/source changes by verifier.

## Focus edges: FAIL
Removing inner clipShape did not resolve flat truncation. True1920x1080 simctl capture, columns-focus-full.png and enlarged crop columns-focus-crop.png, shows white focused Button cut by vertical List bounds at x434 and x1486. Native rounded top/bottom contour ends at these flat cuts. Automatic columns shows same cuts in device-tool960px capture/crop. Device tool screenshots are960x540 despite fullsize filename, so true simctl capture was used for decisive edge inspection.

## Other checks
- Panel remains centered: AX Table434,144,1052x792; screen center960,540. Outer shell rounded, gutters visible.
- PlayPause opens panel and Automatic columns focused; Down focuses Columns.
- PlayPause closes open panel; AX focused Matrix rain with no Table. PlayPause reopens panel and restores Automatic focus.
- Six DeviceInteraction captures plus one simctl screenshot; no matrix sweep. Session ended, simulator released with settings open.

Earlier no-clipping claim based on small screenshots was insufficient; this full-resolution check supersedes it.
