# TV remote cancellation — 2026-10-28

The `Settings` role and `dreams.tv.rain/remote_settings` retain the requirement
that swipe adjustment remain available and directional holds stop on cancellation.
The previous implementation set suppression in the delegate before any recognizer
had started, and a failed pending hold had no action to clear it. The parent
`lifecycle` and `paused_preview` obligations remain unchanged. This is a repair of
the existing descriptive draft, not acceptance of that draft.

The directional hold recognizer starts suppression when it receives a press and
clears it on reset, including the failure path. Existing successful click and hold
handlers and their adjustment units remain in place. The baseline snapshots and
hashes are in [source identity](../../evidence/2026-10-28-remote-cancel/source-identity.json);
the recorded base revision alone does not identify the changed source.

The focused simulator unit test directly exercises the start/reset cleanup path;
it does not synthesize a real cancelled remote press or establish UIKit gesture
arbitration and focus event ordering. The existing hold-repeat, bounds and disabled
field tests are separate. Physical Apple TV verification of cancellation, swipes,
single and double clicks and hold remains outstanding. Prior test and device
evidence stays historical.

Checks on the changed source: `make test-tv` with `RemoteAdjustmentTests`,
Apple TV 4K 1080p simulator and Xcode 27.1 (27A9275), exited 0: four tests
passed. Build output was routed to this worktree's TB5 DerivedData. The later
source snapshot adds only a SwiftLint suppression comment. SwiftLint on the two
changed Swift files exited 0, with its existing `unused_import` configuration
warning. `make specs-check` exited 0 using SpecPM 0.2.0 and Hypercode binary
SHA-256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
The TV map parsed and validated in default and clock-hidden profiles; TV SpecPM
reported no errors and two unresolved external capability warnings: Apple tvOS
and Metal renderer. Other packages retain their own warning-only diagnostics.
