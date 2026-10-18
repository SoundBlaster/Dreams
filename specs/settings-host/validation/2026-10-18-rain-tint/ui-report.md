# Actual rain tint initial QA

Fresh isolated bundle cloned on TB5 with unique ID ru.egormerkushev.dreams.rain-tint-qa and current binary, ad hoc signed. Production and existing SDK QA app untouched.

Observed: Appearance sliders, toggle and rain are green, sidebar SF Symbols remain system blue. Selection material is neutral gray in SDK27 native style. Thus detail-level .tint does not by itself tint the sidebar symbols.

ColorPicker limitation: NSColorPanel appears to be created (isolated defaults contain NSColorPanel frame/toolbarconfiguration), but CUA bound mainwindow AX/screenshot do not include its controls. Show color panel action, click, coordinateclick and keyboard activation did not expose a targetable color editor. Bounded attempt stopped; live red/blue/profile change not verified. Last AX colorwell rgb.158129 .53885 .224135; no claim of restored exact green, because panel/color conversion may have changed isolated test color. CUA rejected final attempted color set with user-changed-state message; mainwindow was refreshed and captured.

Artifact /tmp/dreams-rain-tint-qa/initial-appearance.png and initial-ax.txt. Known top blur band ignored as instructed. No code or production settings changes.

## V2 tint plus accentColor at NavigationSplitView root

Fresh unique bundle ru.egormerkushev.dreams.rain-tint-v2-qa with parent ready binary. Seeded only this domain using typed plist/defaults import; export verified float elements: opaque [.1,.3,.95], transparent [.95,.2,.1], migration marker true.

PASS live profile response: opaque Blue Appearance sliders/toggle/rain; Background transparent switch changed controls and rain to Red immediately; Appearance AX colorwell [.95,.2,.1] and sliders/toggle Red. Returning transparent off restored opaque Blue. No overlay started.

FAIL sidebar recolor: SF Symbol icons remain system blue in Red profile as well as Blue; selected row highlight stays neutral gray. Root .accentColor with .tint did not recolor these native sidebar symbols or selection. Distinguish this from successful detail controls/rain.

PNG artifacts: v2-blue-appearance.png, v2-red-background.png, v2-red-appearance.png, v2-blue-restored-rain.png in /tmp/dreams-rain-tint-qa/. AX evidence v2-blue-ax.txt, v2-red-background-ax.txt, v2-red-appearance-ax.txt. Fresh app left on Rain with original opaque profile restored. All preferences modified belong only to named disposable domain.

## Final V3 listItemTint per NavigationLink

Fresh isolated bundle ru.egormerkushev.dreams.rain-tint-v3-qa, supplied final binary after parent ready; same typed Blue/Red seed as V2.

PASS: Opaque Blue Appearance controls and sidebar SF Symbols match Blue. Toggling Background transparent on live changes rain, sliders, toggles AND all sidebar icons to Red (General, Appearance, Rain, Background, Agent words, Displays, Advanced). Appearance AX Rain color [.95,.2,.1] confirms active profile. Native selected row highlight remains neutral gray; acceptable platform behavior, distinct from now correctly colored icons. No custom row background introduced.

Artifacts: /tmp/dreams-rain-tint-qa/v3-blue.png, v3-red.png, v3-red-ax.txt. Source/runtime approach per parent: root .tint(model.rainColor), per-row .listItemTint(model.rainColor), ineffective .accentColor removed.

Transparent off restored original Opaque Blue, app left on Rain, UI alive. Production/SDK QA preferences and user Fade13 untouched. No ColorPanel or fullscreen actions.
