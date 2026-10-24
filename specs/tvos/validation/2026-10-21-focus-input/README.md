# TV focus input and Release observation — 2026-10-21

Runtime `c9818b9299c981252c78b2f8e1a7b6fc97b46333`. [Source/map identity](../../evidence/2026-10-21-focus-input/source-identity.json) pins the changed SettingsPage and television properties; unchanged snapshots remain historical inputs.

The stable `remote_settings` claim now explicitly includes touch-surface swipes. Settings listens to the native focus engine's failed horizontal movement, preserving vertical List focus and ignoring reset-confirmation input. Tuning, shared simulation, renderer and clock contracts retain their previous requirements. TV draft.3 remains descriptive and unaccepted.

Before this input change, the unchanged `3d2829e` runtime was rebuilt as Release and installed on the owner's Apple TV (AppleTV5,3 / A8, tvOS 26.6), preserving preferences. The owner launched it and reported that the previously described slowdown was no longer observed. This is owner feedback, not a measured FPS comparison or a controlled 160-column/10% search benchmark. Instruments attach attempts could not find the process; an all-process attempt disconnected. No valid trace supports a stronger performance claim. No renderer optimization was made.

[Simulator build](build-simulator.log), [physical-device Release build](build-release.log), [lint](lint.log) and [HC/SpecPM validation](structure.log) passed using verified checkout-specific TB5 output paths. Known unused_import analyzer configuration and external-capability descriptive draft warnings remain. [Identity audit](identity-check.json) checks all 22 source inputs, four maps and two fonts. [Commands and results](runs.json) identify the build configuration and tool identities.

The current Release build [installed successfully](install.log) on the owner's Apple TV without uninstall/reset. Automatic [launch failed](launch.log) because the TV was asleep; it has not been claimed as launched. Simulator input results are recorded separately below. The previous 17-test run remains [historical](../2026-10-21-parity/tests.log). Real Siri Remote swipes and spoken VoiceOver still require physical acceptance.

The [bounded simulator report](report.md) records exact Columns 64 → 65 → 64
steps without duplication, native Down/Up navigation and Play/Pause menu exit
returning focus to the rain. [Right capture](01-right.png), [Left then Down](02-left-then-down.png),
[Up AX](03-up-ax.txt) and [closed AX](04-closed-ax.txt) support these observations.
No clipping or persistent white plate was observed. The original simulator values
were restored and the interaction session ended. Synthetic `r left/right` events
prove discrete commands only, not real touch-surface gestures.

[Documentation links](docs.log) pass. New artifacts preserve historical validation;
no prior test pass is relabeled for this runtime.
