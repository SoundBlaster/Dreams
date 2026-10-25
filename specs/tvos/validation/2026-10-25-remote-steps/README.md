# TV defaults and coarse remote adjustment — 2026-10-25

Runtime/test source `5936633762c5a380c7af11b7f3162d46504e4f0a`, based on
`bcf24bf49860bb04308aa0753b15a36e7fc17ba3`. Owner requests90 columns by default
and ten-step fast adjustment; explicitly confirms holding Left/Right and mentions
the older remote's double edge click. Existing saved values stay unchanged.

## Behavior and responsibilities

New/reset RainTuning and registered defaults use90 columns. Numeric SettingsField
routing applies each field's existing unit and clamps/disabled-state guards.
Native List Buttons, Toggles, vertical focus, swipes and VoiceOver remain.
RemoteHoldAdjustment adds window-scoped UIKit directional single/double tap and
long-press recognizers, accepting only their matching Left/Right press type and
no touch types. Tap failure dependencies avoid firing both single and double.
While a directional press is pending/held, its failed-focus notifications are
suppressed; touch-surface swipes keep the previous focus path. Single click and
swipe use one step, double click ten; hold begins at0.5s and repeats ten steps
at0.2s. Field change, disabled controls, cancellation and window teardown stop
repeats/remove recognizers. No Select, PlayPause or vertical press is claimed.

Ten steps means10 columns,10 fade glyphs,10 percentage points,0.10 speed,
5.0 acceleration or0.50 clock size, bounded by each existing range. Clock
Typeface is categorical and is not a coarse numeric field. EN/RU hints explain
coarse adjustment. No renderer/grid/font changes or desktop input changes.

Affected claims: `dreams.tv.rain/persistent_tuning`, `remote_settings`, parent
lifecycle/paused_preview obligations. Settings/Tuning roles fold the small input
bridge rather than creating a new boundary. FPS semantics/cadence/appearance are
unchanged; only its full-file RainParityTests snapshot is refreshed. Both
packages remain descriptive drafts, with stable claim IDs. Earlier evidence is
historical and not relabeled for this revision.

## Verification and limits

Regression tests exercise a fresh90 default, preservation of saved96, reset and
reload90; numeric ten-step units and clamping; ignored disabled/categorical
controls; actual repeat Task execution and cancellation on detachment. The final
TV run passes25 tests on the tvOS27.0 Apple TV4K1080p simulator. It does not
synthesize a physical hold or double edge click, nor prove gesture arbitration.

A bounded Xcode interaction session launched the app and captured initial rain
hierarchy/screenshot. Its next Select command failed with Session not found;
closing confirmed no live session. No preferences changed in that check, and
normal Columns clicks, hold and double click remain without UI execution proof.
The tool's documented remote syntax exposes single Left/Right only. Physical
owner verification of single/double/hold plus release/focus/close is outstanding.

[Source identity](../../evidence/2026-10-25-remote-steps/source-identity.json).
The local device build intentionally overrides Bundle ID to the already-installed
ru.egormerkushev.DreamsTV so this test install preserves the owner's sandbox.
The checked-in Store target ru.egormerkushev.dreams.tv is unchanged. Installation
and process launch, when recorded, do not imply remote-input acceptance.

Final source5936633 passes25 tests and Release build. The new app is installed
on the physical AppleTV5,3 with the legacy Bundle ID; devicectl install exits0.
The launch exits1 because the system is asleep; wake/relaunch is a separate
operation, not an input/performance acceptance. Raw installation receipts stay
in the local task build directory, avoiding publishing physical device identity.
