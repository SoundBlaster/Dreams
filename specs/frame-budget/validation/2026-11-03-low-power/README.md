# Low Power Mode — 2026-11-03

Runtime source revision `80d05cde2e56a009ed0989d7965488ac9ed8ab7f`, base `550a2859dd7dcf80966fd53f71f4714edc82be57`. Draft contract only.

- macOS release `scripts/swift-macos.sh test -c release --filter RainFrameBudgetTests`: exit 0; four policy tests passed; two opt-in Metal tests skipped.
- tvOS Release simulator build: exit 0; compile only, no simulator test or device observation.
- The system power-mode transition, real FPS, battery/energy and physical devices have not been measured.
- Existing drop-motion, FPS, feed, performance, settings-host and tvOS claims retain their identities: only the frame-rate request policy changes; simulations and their timing remain unchanged. Source bindings were refreshed; earlier tests remain historical evidence.
- `make specs-check HYPERCODE=/Volumes/TB5/Developer/Builds/GitHub/Hypercode-4345ff8dcac12189/swiftpm/debug/hypercode`: exit 0. Hypercode executable SHA-256 `f9631fa8c2dcfe6c1afd57c4919617e13e84838bfc289fb94440740231684e76`; SpecPM 0.2.0. Existing unresolved external-capability warnings remain.
- Frame-budget HC SHA-256 `85c564ec5c862f45ae6494a835f8a3344e15189730ee08b7042b3b928fb5d745`; HCS SHA-256 `d164b878d4341696777994c63b16a77ef85dc091e5637f206b2ed1517905e225`. The dated source identity manifests record the full file SHA-256 values.
- `swiftlint lint --strict --quiet`: exit 0; configuration warned that unused_import belongs in analyzer_rules.
