# TV rain parity — 2026-10-21

Runtime `1857e9288959006c738bc72b9c5e8edc4f3c083c`.
[Source/map/resource identity](../../evidence/2026-10-21-parity/source-identity.json)
pins 22 source/configuration/test inputs, four maps and both unchanged font files.
The map baseline is independent of the source revision: changed/untracked maps
are identified by their digests and snapshots, not attributed to an earlier commit.

The user confirmed rain/settings parity while preserving the TV clock and excluding
agent integrations and desktop-window/session functions. Existing TV defaults and
mirrored variants remain deliberate compatibility choices. The [parity matrix](../../../../tvOS/parity.md)
lists those distinctions. New `dreams.tv.rain` remains a descriptive draft.
Parent TelevisionApplication now points at its own detail. Existing desktop claims
and stable identities remain scoped to macOS; no desktop execution evidence is
relabelled as TV evidence.

## Build, tests and structural checks

[Build](build.log) uses the repository make app-tv entry point, XcodeGen and an
explicit per-checkout TB5 derived-data/product/intermediate root. An initial
exploratory Xcode invocation revealed that global custom Xcode product locations
could override derivedDataPath alone. Make wrappers now supply explicit SYMROOT
and OBJROOT. No source checkout, user cache or prior artifacts were moved/deleted.
The final build log verifies the isolated actual output location.

[Tool identities](tools.json) pin Xcode27.1 / tvOS SDK27 / Swift6.4, specpm0.2.0
and the Hypercode executable digest. Deployment remains tvOS18; this is not a
runtime check on tvOS18 or a physical Apple TV.

[Final tests](tests.log) cover all17 TV tests: existing mask/font/shader/density
checks plus preference migration and persistence/reset, invalid bounds, automatic
grid, linear-light conversion, actual renderer-instance head/gap/UV behavior,
independent pulse colors with unchanged occupancy and glow0. The current bundled
restored font has28 forms; an initial test incorrectly assumed more than28 and was
corrected to check full dynamic font coverage and mirrored UV bounds. No font bytes
or user checkpoints were changed.

The renderer-instance tests exercise production makeCells and actual bundled
atlases/runtime shader compilation. They are not pixel-diff, FPS, television
readability, spoken VoiceOver or macOS acceptance tests.

[Lint](lint.log), [documentation links](docs.log) and [HC/SpecPM structure](structure.log)
record separate outcomes. Known external platform capability warnings remain;
structural success does not establish runtime conformance or owner acceptance.

## Actual simulator input

Apple TV4K1080p, tvOS27 Simulator. Initial EN/RU settings viewports were readable
([EN](en-settings-grid.png), [RU](ru-settings-grid.png)), but these two early
captures precede focus corrections and do not prove final input behavior.

The verifier found two native List integration defects and the implementation was
corrected: explicitly request focus when the dynamic panel appears, then handle
Left/Right at the list boundary because a focused native List cell consumed the
child handler. The accidentally altered English Show clock label was corrected.
Final [adjustment screenshot](en-final-adjustments.png) /
[AX](en-final-adjustments-ax.txt) records directional control behavior.
Right changed density95→96%; Left restored95%. Columns65→64 verified decrement.
Automatic disabled the manual row and navigation skipped it; braking enabled its
acceleration row. Select changed pulse and color. These are simulator observations,
not claims that every value of every control was manually traversed.

[Clock off](en-clock-off.png) / [AX](en-clock-off-ax.txt) confirms the toggle and
clock-dependent rows. [Preview paused](en-preview-paused.png) /
[AX](en-preview-paused-ax.txt) records Off; Select restored On. The [reset dialog](en-reset-confirmation.png)
uses default Cancel. [After cancellation](en-final-settings-after-cancel.png) /
[AX](en-final-settings-after-cancel-ax.txt) retains clockOff, pulse31% and red10%,
confirming cancellation did not reset preferences. An independent Back closed the
panel and restored rain focus. A Back chained immediately after Cancel was
swallowed during system dismissal; no application defect is asserted from that
transition timing. No test-only delay or custom modal behavior was introduced.

The verifier session was explicitly ended. Test preferences belong only to the
TV simulator; no production desktop preferences, hooks or system settings changed.
Actual spoken VoiceOver, physical Apple TV, overscan/viewing-distance readability,
long-run frame performance and tvOS18 runtime remain unverified.

[Identity audit](identity-check.json) confirms all current files and snapshots match.
[Command records](runs.json) preserve working directory, source revision and exit codes.
[Operator report](operator-report.md) retains the initial failures and final observations.
