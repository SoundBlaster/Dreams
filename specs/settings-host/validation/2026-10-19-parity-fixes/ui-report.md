# Parity fixes actual-app QA

Fresh isolated EN Dark normal release bundles, no source/build/harness or production settings changes. No reset/hooks. Initial source bf97bd9, final targeted Rain source73417b9 as parent-provided identities. RU not repeated because parent bounded final recheck to Rain only.

## Initial bf97bd9 actual checks
- General runtimehint `dreams.run-time-hint` appears with1hour/fullscreen/Esc/pointerExit/backupshortcut. Runtimepicker and shortcutbutton expose Help in AX.
- Recording: Return remains in recording with invalidmodifier guidance; no overlay starts. Esc restores Change shortcut, original⌃⌥⌘D unchanged. Evidence recording-return-ax.txt.
- Displays adds Built-in · Main suffixes to same hardware row, screenshot/AX displays-en.*.
- Ordinary Return from General opens actual Dreams Rain window with ExitEsc control. Immediate Esc closes overlay, restores settings and status Stopped withEsc. Evidence return-start.* and escape-stop.*. No overlay left active.
- Initial Rain sliders still lacked AX help while switch Decelerate had Help. Preserved rain-en-ax.txt is BEFORE providerfix, notfinal proof.

## Final73417b9 targeted Rain
- rain-final-73417b9.png and -ax.txt. No visual layout regression. Labels, stableIDs, values preserved for Columns/Density/Speed/Fade/acceleration/Searching.
- Help explanations now appear on those nativecontrol records in CUA, but printed as the role/type text instead of literal slider or separate Help field. Example Speed record: `0.25× is slow; 1× is normal; 3× is fast. (settable,float) Description:Speed ... ID:dreams.rain-speed`. Therefore additional explanatory accessibility text is confirmed, but underlying AXRole/AXHelp mapping is not independently measured; parent notified of this exact representation.
- CUA has no documented hover API; visualtooltip popup not tested.

All screenshots and AX evidence are in thisdirectory. No further UI cases or settings edits after final Rain capture.
