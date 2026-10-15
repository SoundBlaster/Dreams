# Actual app keyboard check — 2026-10-15

Device-interaction subagent used CUA on the isolated `ru.egormerkushev.dreams.preview-verification`
application. Built app: `dist/native-preview/Dreams Preview.app`, native launch flag.
The existing user application/fullscreen session and its preferences were not changed.

- General: Change shortcut starts capture. Plain A keeps capture active and shows guidance.
- Esc cancels capture without closing settings; second Cancel also cancels.
- Rain → General cancels capture; minimize → raise also cancels.
- Control+Option+Command+F18 records successfully; Default restores Control+Option+Command+D.
- First pass exposed a duplicated hint and private-use F18 glyph. Both were fixed.
- Final build retest confirms distinct invalid-key guidance and readable F18 in value/hint;
  Default restores the original key. Screenshots and accessibility trees were inspected in CUA.
- Actual app Default conflict was not reproduced; the controlled Carbon conflict regression
  supplies separate registration-failure evidence.

No VoiceOver, macOS 15, physical multi-display or fullscreen exit acceptance is asserted.
