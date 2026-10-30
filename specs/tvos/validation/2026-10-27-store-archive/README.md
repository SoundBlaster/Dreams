# Local Dreams TV App Store archive — 2026-10-27

Source `b3b6fbc553226bc0f1fa2342d9bd32337d4b5e96` was archived and exported
locally as Dreams TV1.0/build1. No app source or assets changed since the reviewed
runtime source dfa87c906a141a5d7c6d6cab6ffecdf9bc710bf5. The owner selected the
existing green Dreams mark. This run does not replace earlier test/device evidence.

## Specification scope

`TelevisionApplication.Packaging` / `dreams.tv.rain/store_packaging`, `resources`
and `platform_boundary` retain their existing requirements, source bindings and
draft acceptance. This adds artifact evidence only, with `Spec-ID: NO-SPEC-IMPACT`
for requirements/implementation; no map or contract edits are needed. Structural
validation was not rerun because those inputs are unchanged. Their hashes and
actual command exit codes are retained in [checks](checks.json).

## Artifact verification

The [artifact manifest](../../../../tvOS/app-store/build-1.0-1.json) pins IPA and
executable SHA256, version/build, SDK, team and checked properties.
Xcode27.1/27A9275, tvOS27.0 SDK and the preflight-verified checkout-specific TB5
paths were used. Archive and local export both returned0. Explicit export options
use app-store-connect with destination=export; no upload/wait/review action ran.

The exported IPA was extracted and checked independently of project settings:
AppleTVOS/family3, arm64, minimum tvOS18.0, registered Bundle ID/team/application
identifier, valid Apple Distribution signature, get-task-allow=false, unexpired
App Store profile with neither device restrictions nor all-device provisioning.
Privacy declarations and every required resource passed the existing checker.
Linked libraries contain no AppKit or ScreenSaver framework; this is not an
exhaustive API audit.

The compiled asset catalog contains the opaque1280×768 marketing icon, both
layers of the Home Screen and store icons, and standard/wide Top Shelf assets.
This confirms packaged resources, not actual Home Screen parallax or store UI.
The only archive warning skips AppIntents metadata extraction because this target
has no AppIntents.framework dependency.

## Remaining limits

No tests or device run were repeated for this unchanged source, and the exported
IPA was not installed. Local signing/export does not establish App Store
processing, accepted toolchain, TestFlight, review acceptance or publication.
Font redistribution rights, agreements and remaining submission gates stay in
the [release checklist](../../../../tvOS/APP_STORE.md). The IPA remains local.
