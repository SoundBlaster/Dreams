# Final native focus-edge check

Runtime3d2829e24453c6dac5a2c879822e50d7416bd9f8; parent-built app installed on Apple TV4K1080p tvOS27 Simulator B29EC156-5EF9-4A56-8147-1C98D4E228DB. PID68544. No verifier source/build changes.

PASS: .scrollClipDisabled() resolves previously observed vertical flat cuts. True1920x1080 simctl captures automatic-full.png and columns-full.png plus enlarged crops show complete smooth native rounded contours at both left/right focus edges. Focus outline can now extend outside List bounds instead of being cut at x434/x1486. Automatic and numeric Columns both verified. Native focus, centered panel and outer rounded shell retained. Table434,144,1052x792 midpoint960,540; full-image panel extends symmetrically around table.

PlayPause opened menu in this runtime. Close/reopen passed on preceding d566578 runtime; not repeated here after parent narrowed final verification to focus edges. Routing unchanged by scroll clipping modifier.

Session ended and simulator released. Final settings open with Columns64 Focused. Failed prior attempt and decisive flat-cut crop preserved in attempt-1.

No physical Apple TV, VoiceOver speech or performance conclusions.
