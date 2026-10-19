# Preview help width actual-app QA

PASS: actual isolated EN Dark700x600 window, parent-authorized temporary launch sizing harness. App `Dreams Width QA.app`, domain `ru.egormerkushev.dreams.help-width-qa`. No production app/preferences changed.

- Appearance: help panel and Live Preview header share left/right edges (approximatelyx472..1368px in1400px screenshot). Text wraps readably.
- Rain: same left/right edges, same header/footer positions as Appearance. No horizontal crop or additional downward jump observed.
- Only Appearance and Rain navigation, no other cases.

Artifacts: `appearance-700.png`, `rain-700.png`, matching AX files.

TB5 preflight succeeded; harness build used scripts/swift-macos.sh build release with checkout-specific scratch/cache paths. Full log `build.log`. SourceWindow restored byte-for-byte: True. Normal release binary restored byte-for-byte: True. Normal SHA256 `57cbfec5555714178353f829bc50fe38067124290c41a56a4e047b18e6820004`. Dedicated harness saved outside source checkout under TB5 help-width-harness/Dreams.
