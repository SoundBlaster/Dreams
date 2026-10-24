# Native macOS appearance recipes and quick colors — 2026-10-21

Runtime `aa11113675d1a5046c01cfb570d939ae5df29b14`.
[Source/map identity](../../evidence/2026-10-21-appearance/source-identity.json) and
[hash audit](identity-check.json) cover 46 source inputs and 16 maps. The new
`quick_appearance` claim is folded into Forms and SettingsBinding in draft.21.
Stable native_controls, one_settings_owner, operation_semantics,
material_composition, independent_preview and default_off remain applicable.
No catalog-library, tvOS, overlay algorithm or agent integration change is made.

## Behavior and verification

Three native button-style Toggles apply appearance recipes. Classic uses the
existing defaults for the active background, Dimmed multiplies its green by 0.65
and glow by 0.25 with spread 0.3/pulse 0.1; Monochrome uses neutral 0.8 RGB on black
or 1.0 over windows, glow 0.15/0, spread 0.25/pulse 0.1. Recipes retain grid, motion,
glyphs and agent settings. Color/glow retain their existing profile split;
spread/pulse remain shared. Eight named native palette Buttons change only color.
Preset and swatch selection derive from actual values with 0.0001 conversion
tolerance; unmatched manual edits show Custom. Nothing persists a second preset
name or creates another settings owner. Existing notifications refresh legacy,
live preview and rain-color window tint. The existing native feature flag remains off.

[21 native-settings tests](tests.log) passed, including profile persistence,
unchanged motion/grid/inactive-profile checks, single swatch selection, manual
color/parameter edits and restoring a known recipe. The in-process profile reload
explicitly requests its background because DreamsController caches the initial
launch profile per process. [Release app build](build.log) passed through make app;
SwiftPM outputs and dist were routed to the verified checkout TB5 root. Two optional
per-process SwiftPM path overrides in swift-macos.sh allow the existing build/trace
wrappers to preserve routing; explicit command flags take precedence. Temporary
source-tree dist/venv links were removed after the build; font output is unchanged.

Screener SDK 0.2.0 completed [EN](trace-en.log) and [RU](trace-ru.log) runs of 35
explicit state frames each. [EN timeline](trace-en/timeline.jsonl) and
[RU timeline](trace-ru/timeline.jsonl) retain marker metadata; selected witnesses:
[English narrow](trace-en/appearance.palette.narrow.png),
[Russian narrow](trace-ru/appearance.palette.narrow.png),
[English Classic](trace-en/appearance.preset.classic.png).
Screener MCP read the fresh EN timeline and narrow keyframe. These are hierarchy
captures: materials, selection pixels and Metal output can be omitted or altered.
The large-text hierarchy frame was inconclusive and is not visual acceptance.

The [ScreenCaptureKit attempt](screen-capture-attempt.log) ended without a completed
scenario (trace contained only sessionStarted); it is not counted as a pass or
silently relabelled as compositor evidence. CUA independently inspected the actual
isolated QA app (bundle ID ru.egormerkushev.dreams.appearance-qa). Actual native
clicks applied Dimmed, Blue, Monochrome and Classic, with expected readout changes.
Blue exposed a native selected Button, removed recipe selection and showed Custom;
[actual screenshot](blue.png) and [AX snapshot](blue-ax.txt) show the color well,
blue rain and blue window controls. [Classic](classic.png) and
[Monochrome](monochrome.png) are actual CUA window captures. A later slider click
changed pulse to 50% in this QA process; Monochrome then reset it to 10%, and Classic
restored its defaults. The isolated QA process was terminated after inspection.
Production app preferences/hooks were not used for this operator sequence.

[Lint](lint.log), [Hypercode/SpecPM structure](structure.log) and
[documentation links](docs.log) pass. Known unused_import configuration and external
capability warnings remain. [Command/tool record](runs.json) pins exits, paths and
versions. Contracts remain descriptive drafts. macOS 15 runtime, complete keyboard,
VoiceOver speech and assistive input acceptance remain unverified; trace coverage
and source checks do not establish those outcomes. No CI watching or release here.
