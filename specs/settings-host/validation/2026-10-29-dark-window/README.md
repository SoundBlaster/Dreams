# Dark settings windows — 2026-10-29

The owner requested a consistently dark desktop settings window. Both native
and legacy settings hosts set their window appearance to Dark Aqua, independent
of the system theme. The `native_controls` and `explicit_legacy_access`
claims retain their identities; the shared settings owner, preview, selection,
tint and window lifecycle obligations remain unchanged.

The [source identity](../../evidence/2026-10-29-dark-window/source-identity.json)
pins the changed files against the base revision. Earlier evidence remains
historical; this change does not establish appearance of other app windows.
The contracts remain descriptive drafts, not owner acceptance.

On this source, `swift build` and the targeted
`NativeSettingsTests/bothWindowsSharePreferencesAndOneActivityTimer` test
passed using the checkout-specific TB5 scratch path. The test verifies each
window's explicit appearance; it does not prove rendered pixels. The compiler
reported the existing unreachable-code warning in PerformanceRun.swift.
Device Interaction did not recognize the Swift package as an open Xcode
workspace, so real-window and light-system-theme visual checks remain open.

`make specs-check HYPERCODE=/Users/egor/Development/GitHub/0AL/Hypercode/.build/debug/hypercode`
exited 0. Hypercode parsed and validated the settings host for native and legacy
profiles. SpecPM 0.2.0 reported no errors and three unresolved capability
warnings: dreams.settings.ui, platform.apple.metal_renderer and
platform.apple.swiftui. Hypercode binary SHA-256:
`6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
Source and map hashes are recorded in the linked identity file.
