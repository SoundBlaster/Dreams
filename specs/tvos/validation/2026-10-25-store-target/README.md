# Apple TV App Store target — 2026-10-25

Packaging source `3d21233c0f90e827543a9329df7a7e49b4ffd4a9` prepares the registered
`ru.egormerkushev.dreams.tv` application for a local App Store export. Read-only
ASC queries confirmed app6826786729, a TV_OS-only version1.0 in
PREPARE_FOR_SUBMISSION and Bundle ID team prefix P8T2366K8X. App metadata,
release type, uploads, tester distribution and review submission were not changed.
Automatic provisioning may create/reuse signing assets; none were revoked.

## Claims and baseline

`TelevisionApplication.Packaging` contributes new `dreams.tv.rain/store_packaging`.
Existing resources/platform_boundary obligations still require fonts/notices,
tvOS18+, shared sources and no desktop/agent integration. Lifecycle, remote,
clock, motion, search, pulse, FPS algorithms and saved keys are unchanged.
The new identifier has a separate sandbox, without automatic migration from the
old developer app. The new packaging binding replaces the historical project.yml
binding, while other unchanged source snapshots retain their identities.

[Input identities](../../evidence/2026-10-25-store-target/source-identity.json)
pin configuration/scripts, original artwork and all generated asset files.
Binary assets remain committed at the source revision instead of being duplicated
in this package. Draft status and unaccepted physical/distribution obligations
are preserved; structural validity is not product acceptance.

## Local checks

Xcode27.1 (27A9275), tvOS SDK27.0 and verified TB5 checkout-specific output paths
were used. The first archive compiled/signed but failed with a missing
BuildProductsPath because explicit OBJROOT/SYMROOT conflicted with custom global
build locations. Per-process `-IDEBuildLocationStyle=Unique` and
`-derivedDataPath` restored archive's own intermediate layout on TB5 without
changing global preferences. The first IPA then failed the actual-product check:
XcodeGen had not copied the extensionless LICENSE reference. Explicit Resources
membership fixes this; final archive, App Store export and product check pass.
Failures are preserved in the diagnostics alongside the passing final runs.

The exported app has version1.0/build1, AppleTVOS/family3, deployment18.0, correct
team/application identifier, an Apple Distribution signature, get-task-allow=false,
and no device-limited/all-device provisioning. Actual resources include the
compiled TV icon/Top Shelf assets, privacy manifest, both fonts, shader and both
license/notice files. The linked-library list contains Apple system/Swift
libraries; this is not an exhaustive API audit. Manifest declarations reflect
local rendering and own-app settings, distinct from ASC App Privacy answers.

All19 existing TV unit/renderer-instance tests pass on tvOS27.0's Apple TV4K
(3rd generation),1080p simulator after the final packaging fix. Test logs contain
repeated-font-registration and 'Each CAMetalLayerDrawable can only be presented
once!' messages. Passing tests do not resolve those separate runtime observations.
No physical-device or long-duration performance/memory run occurred here.

Generated icon source PNG was visually inspected. Regeneration is byte-identical
across24 asset files; this does not verify actual Home Screen parallax, Top Shelf
UI, owner visual acceptance or store screenshot suitability.

## Separate release gates

This is a local inspectable IPA, not an uploaded/submitted build. Font
redistribution-rights review, App Store toolchain acceptance, physical/long-run
checks, TestFlight, product metadata/privacy answers and manual-release selection
remain explicit in [the release checklist](../../../../tvOS/APP_STORE.md).
macOS/agent integration behavior was not changed or newly validated.

[Commands and results](checks.json) distinguish tools, source/map hashes, exit
codes and diagnostics. [Bundle inspection](bundle-check.json) records the final
product. Historical passes do not establish this new packaging baseline.
