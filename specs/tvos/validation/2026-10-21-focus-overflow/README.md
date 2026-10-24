# TV native focus overflow repair — 2026-10-21

Runtime `3d2829e24453c6dac5a2c879822e50d7416bd9f8`. [Source/map identity](../../evidence/2026-10-21-focus-overflow/source-identity.json)
pins one changed SettingsPage snapshot and reuses unchanged previous snapshots.
The inner List `clipShape` cropped native focus enlargement horizontally. Remove that mask and disable native scroll clipping with `scrollClipDisabled()`;
this preserves the 24-point spacing, 28-point rounded material shell, centered
panel and Play/Pause routing. `remote_settings`, `lifecycle`, `platform_boundary`
and current maps still apply; no contract text or role identities changed.

The earlier centered-menu report's claim of no clipping was incorrect for focused
row edges: the user's enlarged screenshot showed flat side cuts. That report is
retained as historical evidence, with this correction superseding its edge claim.

[Build](build.log) passed on verified checkout-specific TB5 output paths.
The earlier [17-test run](../2026-10-21-parity/tests.log) is historical, not rerun for
this view-only mask correction.

[Lint](lint.log) and [Hypercode/SpecPM validation](structure.log) passed. The existing
unused_import analyzer configuration and external-capability draft warnings remain.
[Identity audit](identity-check.json) verified all 22 source inputs, four maps and
two font hashes against current source/snapshots. [Commands](runs.json) record
exit codes and output paths; unchanged [tool identities](../2026-10-21-parity/tools.json)
are Xcode 27.1, tvOS Simulator SDK 27.0, Swift 6.4, SpecPM 0.2.0 and the pinned
Hypercode executable hash.

First correction attempt `d566578a16893d0804da883b8789aff7f26812b7` built but
failed the full-resolution edge check: the native scroll viewport still clipped
the expanded highlight. The final correction also disables scroll clipping,
allowing expansion into existing panel padding. The outer shell remains clipped
to its rounded shape; row input, focus ownership and preview lifecycle are unchanged.

Full-resolution 1920 × 1080 simulator captures now show complete smooth native
left/right contours for both the [Automatic columns toggle](automatic-crop.png)
and the [Columns button](columns-crop.png); the flat cuts are gone. The
[full settings viewport](automatic-full.png) and [AX capture](automatic-ax.txt)
retain the centered padded material panel. The [operator report](report.md) records
the failed first attempt separately from the final successful runtime.

[Documentation links](docs.log) pass. Physical Apple TV, tvOS 18 runtime and spoken
VoiceOver remain unverified. No new acceptance state is implied by structural or
simulator checks.

The first attempt's [report](attempt-1/report.md) and [failed edge crop](attempt-1/columns-focus-crop.png)
are retained. Final [Columns AX](columns-ax.txt) and [full frame](columns-full.png)
supplement the crops. Play/Pause opened settings on the final runtime; close/reopen
passed on the preceding attempt, with unchanged routing. The final verifier session
was ended and the simulator released.
