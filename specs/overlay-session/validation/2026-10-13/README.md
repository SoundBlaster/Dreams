# Overlay structure validation — 2026-10-13

Source: merged main `1ce194748720e40e1eb9737e63bb37797c5840b1` in an isolated
worktree, with only additive specification/Makefile changes. Original user
checkpoints/manual glyph files were neither copied nor changed.
[Input identities](../../evidence/2026-10-13/source-identity.json) include full
source hashes and exact excerpt ranges; snapshots were verified against them.

## Results

- Application and overlay HC maps parsed and validated (exit 0).
- Four overlay profiles validated (interactive/agent × opaque/transparent).
  [Resolved profile checks](profile-checks.json) additionally assert the declared
  duration/input values, including finite agent duration in transparent mode.
- Overlay [SpecPM result](specpm.json): **0 errors / 11 warnings**, exit 0.
- Existing glyph [package check](glyph-package-regression.json): **0 errors / 8
  warnings**, exit 0. Its implementation bindings/claim IDs are unchanged.
- `make specs-check` checked all current application/editor/overlay maps and
  both packages. No application or display-changing tests were executed.
- Markdown links and staged whitespace checks passed; actual commands and
  complete diagnostics are recorded in [runs](runs.json). Current source/map
  snapshots were also compared to the identities linked above.

[Tools](tools.json) identify the Hypercode binary by SHA-256 (resolver reports
0.6.0-dev; build revision unknown) and SpecPM 0.2.0 executable/schema identities.
HC validation currently has no domain `@contract` rules: syntax/cascade and
resolved declarations do not prove runtime behavior.

## Warnings and verification limits

All eleven overlay warnings are MVP `required_capability_unresolved` messages:
four internal child-capability uses and seven external platform uses. The
external prerequisites are WindowServer, Metal renderer creation, Carbon
hotkeys and IOKit power assertions. They remain explicit; package declarations
and a source review do not prove host capability availability.

No fresh app build, UI capture, physical Escape/hotkey, accessibility, clamshell,
monitor disconnect/reconnect, global shortcut rollback, capture-exclusion or
power-resource test was run. Existing opt-in test code is an expectation only;
its historical observations are not imported as current evidence. Code-derived
issues O1–O6 remain review decisions in the matrix; no runtime fixes or formal
acceptance were performed.

## Re-run

From the repository root, with Hypercode/SpecPM on PATH:

```sh
rtk proxy make specs-check
rtk proxy python3 scripts/check-docs.py
rtk proxy git diff --check
```

Use `HYPERCODE=/absolute/path/to/hypercode` when the CLI is only available as
a local binary. Add a new dated evidence/validation baseline after a relevant
source change rather than overwriting this historical record.
