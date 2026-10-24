# tvOS rain parity simulator audit

- Device: Apple TV 4K 1080p, tvOS 27, B29EC156-5EF9-4A56-8147-1C98D4E228DB.
- Installed parent-built Debug app, bundle ru.egormerkushev.DreamsTV. No source modifications or builds by verifier.
- English launch PID14524. Retained simulator preferences observed: 64 columns, 95% density, speed0.40, fade2.
- English native List settings first viewport: labels readable; background rain continues live. Select opened panel.
- BUG: no Focused element in settings AX; Down/Right and PlayPause ineffective after panel opened. Back closes panel and restores Focused Matrix clock. Reproduced twice.
- BUG: settings.clock.visible incorrectly labeled Show rain in English source and AX; sent to parent.
- Russian launch PID15066 using per-launch -AppleLanguages (ru) and -AppleLocale ru_RU. Initial settings viewport readable with no clipping. Same focus issue.
- Parent rebuilding explicit focus initialization and corrected clock label. Further checks paused pending new product.
- DeviceInteractionSynthesize applicationState=NotRun is misleading here: screenshot and AX show live app PIDs. Session is non-workspace and app launched via simctl.

## Final verification after fixes
- Explicit focus initialization fixed missing focus. Automatic columns receives native white focus.
- List ancestor directional handler fixed Left/Right: Rain density95% -> Right96% -> Left95%. Manual columns64 -> Right65 -> Left64 before moving to reset.
- Automatic On disabled manual Columns; focus skipped it. Automatic restored Off at final.
- Native toggle Select worked for braking and clock visibility. Clock Off disabled Floating/font/size, and down skipped them.
- Select increased pulse30% ->31%, red9% ->10%, acceleration-12.0 ->-11.5. These isolated simulator changes retained.
- PlayPause in settings changed Live preview On ->Off (AX switch value0), with background frozen. Select on preview resumed On (AX value1).
- Restore defaults opens native confirmation with Cancel focused. Select Cancel dismissed it; clock remained Off with pulse31%/red10%, proving no reset occurred. Chained Back immediately after dismissal was swallowed during animation; final capture remains settings at reset row, no modal. Independent Back closed panel and restored rain focus in an earlier capture.
- Final app PID23652, settings panel open at reset row, clock Off. Session ended, simulator released to parent.
- EN/RU first viewport readable without clipped labels. Deep Russian scrolling not repeated after final fix.
- No physical Apple TV, VoiceOver speech, performance profiling, or per-effect numeric pixel analysis performed. No production/macOS settings changed.
