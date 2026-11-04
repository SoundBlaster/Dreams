# Glow default — 2026-11-04

Source `defabe79eec08d06d6e8f686bba25cb91cc0c011`. Descriptive draft; source identities and hashes are in each affected package's `evidence/2026-11-04-default-glow`.

macOS Release `scripts/swift-macos.sh test -c release --filter RainFrameBudgetTests`: exit 0, five policy tests passed and two opt-in Metal tests skipped. tvOS Release test attempt exited 65 at compile because the app module lacked `-enable-testing`; no test body ran. The Debug retry is recorded below. Existing saved values and platform distinctions are unchanged; presets Classic and Dimmed follow the shared default. No physical-device, energy, actual FPS or visual acceptance claimed.

- Debug tvOS Simulator targeted test `RainParityTests/testGlowDefaultAndSavedPreferenceOnNewerHardware`: xcodebuild exit 0; xcresulttool summary reports 1 passed, 0 skipped, 0 failures on Apple TV 4K (3rd generation), tvOS 27.0 simulator.
- `make specs-check HYPERCODE=/Volumes/TB5/Developer/Builds/GitHub/Hypercode-4345ff8dcac12189/swiftpm/debug/hypercode`: exit 0. Hypercode executable SHA-256 `f9631fa8c2dcfe6c1afd57c4919617e13e84838bfc289fb94440740231684e76`, SpecPM 0.2.0; unresolved external-capability warnings persist.
- Television HC SHA-256 `de44f06c65b7fd18460ee7f7f2100e733eac3859780495696e5c3c9f4f54e55e`, HCS `461198c87dcacad77dfc3ed3712893c6587e28401577ff3cde02113658436539`.
