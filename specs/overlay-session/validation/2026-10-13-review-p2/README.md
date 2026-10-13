# PR #17 P2 review correction — 2026-10-13

Corrects `dreams.overlay.exit/button_visibility` after
[review feedback](https://github.com/SoundBlaster/Dreams/pull/17#discussion_r4259051983).
The descriptive draft now matches `pointerOverButton` tracking; a stationary
cursor already over Exit is not a guaranteed auto-hide inhibitor. Matrix O7
records this limitation without changing runtime behavior.

Implementation is still pinned to merged main `1ce1947`; reviewed source is
unchanged from the [original identities](../../evidence/2026-10-13/source-identity.json).
HC maps and profiles are unchanged. The [initial validation](../2026-10-13/README.md)
remains historical. [This run](runs.json) records commands, exit codes, diagnostics,
current input hashes and tool identities for the correction.

`make specs-check` and Markdown/whitespace checks pass. Overlay SpecPM reports
0 errors / 11 unresolved-capability warnings; the glyph package remains at
0 errors / 8 warnings. This establishes structural validity only. No application
build, UI/keyboard or physical display test was performed, and draft acceptance
is unchanged.
