# Actual-app Rain QA

Source supplied by parent: codex/rain-settings-composition, updated isolated release bundle.

- Actual wide window is 1000x800 pt (2000x1600 PNG). EN and RU Light inspected using CUA screenshot plus AX. Rain header, description, Grid/Motion/Searching glyphs and values are readable. No content-overlapping full-width fixture band observed. The outer foundation is rectangular. Large glyphs render behind the form/open preview.
- Pause/Play accessibility label switches and returns; isolated settings values were not altered.
- Reduce Transparency and Increase Contrast were each tested on the actual RU Light window: opaque white foundation and preview controls; contrast gives stronger borders. Both original values were off, restored and verified off in fresh System Settings AX. System Settings restored to original General page. Global appearance was not changed.
- Narrow resize via CUA bottom-right drag had no effect. No documented native setFrame API, so 560x450 and 1000x720 exact sizes remain unverified.
- Dark attempt via app-specific AppleInterfaceStyle plus argument remained Light because diagnostic Info.plist has NSRequiresAquaSystemAppearance=true. Original AppleInterfaceStyle key was absent; temporary key was removed. Info.plist was not changed. Dark unverified pending disposable bundle preparation.

Artifacts:
- /tmp/dreams-rain-qa/en-light-wide.png
- /tmp/dreams-rain-qa/en-light-wide-ax.txt
- /tmp/dreams-rain-qa/ru-theme-attempt-wide.png (visually Light)
- /tmp/dreams-rain-qa/ru-wide-ax.txt
- /tmp/dreams-rain-qa/ru-light-paused.png
- /tmp/dreams-rain-qa/ru-light-reduce-transparency.png
- /tmp/dreams-rain-qa/ru-light-increase-contrast.png

## Dark actual follow-up

- Historical diagnostic-only NSRequiresAquaSystemAppearance=true was removed from the isolated app Info.plist as requested by parent; isolated bundle was ad hoc re-signed. No repository or production plist changes.
- Actual RU Dark Rain was successfully launched and captured: /tmp/dreams-rain-qa/ru-dark-wide.png and ru-dark-wide-ax.txt. Toolbar and material are visibly Dark; white section labels, readouts, description and helpers remain readable. Outline around preview visible. No overlapping full-width content band.
- After stopping only that diagnostic PID99384, two EN Dark launch attempts exited with SIGKILL/137 immediately and no app log. codesign --verify --deep --strict exited0. Cause unknown; do not relabel this as application functional defect without further evidence. EN Dark remains unverified.
- Temporary per-app AppleInterfaceStyle Dark key removed again to restore originally absent key. Global theme unchanged, Reduce Transparency and Increase Contrast restored off/off. Current diagnostic app no longer running.
- Exact narrow frame deferred to parent focused SCK trace; no additional CUA resize attempts.

## Fresh EN Dark actual completion

Fresh new-inode isolated bundle supplied by parent: /Volumes/TB5/Developer/Builds/GitHub/Dreams-36273a9c832f69b9/rain-composition-app/Dreams Rain QA.app, bundle ru.egormerkushev.dreams.rain-composition-qa. Launched successfully using DREAMS_LANGUAGE=en and -AppleInterfaceStyle Dark; no defaults change was necessary. Actual Rain screenshot and AX saved as /tmp/dreams-rain-qa/en-dark-fresh-wide.png and en-dark-fresh-wide-ax.txt. Visibly Dark toolbar/material, readable Rain description, Grid/Motion/Searching glyphs labels, values, helper, Live Preview. Metal glyphs visible, no overlapping full-width band. EN Dark is now verified. Earlier SIGKILL remains a failure of the old diagnostic artifact, not reproduced with fresh bundle. No settings changed. App left open on Rain.
