# Native/legacy parity fixes — 2026-10-19

Runtime `73417b92aaf89c85b9f1bc7106b1d0fd1ec25691`. [Source/map baseline](../../evidence/2026-10-19-parity-fixes/source-identity.json).

Five corrections were committed separately: reset completion on both success and
failure; existing localized help; shared duration/exit explanation; shared display
role labels; system Return default action for Start. Slider ranges/steps, persistence
keys, renderer, slider steps and default-off routing remain unchanged.

Reset now attempts shortcut registration and legacy sync in defer, matching the
legacy post-error path. Production calls the same controller reset; a defaulted
internal reset-command injection supports deterministic partial-reset failure tests
without starting an overlay or changing real displays. Carbon registration remains
fallible; no atomic reset or rollback promise is added. Shared duration formatting
and display-title composition remove presentation duplication.

Host draft.19 folds these details into native_controls/operation_semantics; stable
Forms, SettingsBinding, ShortcutRecording and LegacyAccess roles retained. Parent
one_settings_owner, overlay_exit, range_units and lifetime obligations still apply.
The shared provider/catalog now also exposes optional direct Slider help; unrelated profiles are unaffected. Historical evidence
retains its source baseline. Added DisplaySettingsView and regression-test snapshots
make the shared legacy/native presentation boundary explicit.

## Verification observations

The new partial-reset test was run before the defer correction and failed both
Carbon ownership checks: old key stayed occupied and new key was available. After
the correction it passed. Full NativeSettingsTests then passed19 tests, including
eight duration/background cases, shared-window synchronization, display labels and
recording/registration checks. Conditional Metal/trace cases remain skipped.
These are command observations, not a claim that an unpreserved full log is attached.

Lint passed with the existing unused_import configuration warning. An accidental
duplicate help mapping in the navigation enum was caught by compilation and removed;
all successful build/test results below apply after that correction.

[Release build](build.log) passed20.78s through the SDK27/minos15 helper on
verifiedTB5 scratch. [Structural log](structure.log): make specs-check exit0;
HC parse/profile checks and SpecPM remain separate from runtime acceptance.
Known external capability draft warnings retained. All60 current source/map and
snapshot identities match. Hypercode SHA256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`; specpm 0.2.0.

A row-level SwiftUI help modifier did not expose Help on its native Slider in
actual AX inspection. Corrected the provider with an optional localized help
argument (default nil), attached directly in both system Slider branches; host
passes existing resources. Catalog draft.10 describes this presentation-only API.
[Final release build](final-build.log) passed12.71s; catalog release build passed2.83s.
[Final settings tests](settings-tests.log) passed19 tests (eight duration/background
cases), with the same conditional Metal/trace skips. The earlier build log is
retained only as the earlier pre-provider-correction observation.

Final structural checks: make specs-check exit0. Current source/map/snapshot
identity audit passes60 entries; known draft platform-capability warnings retained.

## Actual application verification

[Operator report](ui-report.md) preserves source-version distinctions and capture
limits. [General](general-en.png)/[AX](general-en-ax.txt) show the runtime explanation.
[Displays](displays-en.png)/[AX](displays-en-ax.txt) include Built-in/Main suffixes.
[Recording Return](recording-return-ax.txt) stays in recording and Esc cancels.
[Return start](return-start.png)/[AX](return-start-ax.txt) opens a real isolated
opaque overlay; [Esc stop](escape-stop.png)/[AX](escape-stop-ax.txt) stops it. No
active overlay remained. These bf97bd9 observations precede the provider-only help
correction; the corresponding host behavior/source is unchanged at73417b9.

[Final Rain](rain-final-73417b9.png)/[AX](rain-final-73417b9-ax.txt) shows the final
provider correction. CUA exposes the explanations on the same settable numeric
control records with preserved labels/IDs/values, but renders explanation text as
role/type text. Raw AXRole/AXHelp mapping was not independently measured, nor was a
hover tooltip popup. Do not treat this as complete VoiceOver acceptance. The
initial [Rain AX](rain-en-ax.txt) is explicitly BEFORE the provider correction.

Fresh isolated EN Dark apps; no production preferences, hook installations or
system theme changed. No reset was clicked. The failure path is covered by Carbon
regression tests instead. RU, macOS15 runtime and full assistive-technology behavior
remain unverified for this baseline. No default-on rollout or release is claimed.
