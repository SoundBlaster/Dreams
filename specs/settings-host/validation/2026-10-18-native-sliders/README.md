# Native sliders and linked SDK appearance — 2026-10-18

Runtime `6c464040ddac981596bebb931450f5ab48e1840d` includes slider cleanup `d65a904` and build routing `6c46404`.
[Host identity](../../evidence/2026-10-18-native-sliders/source-identity.json) pins source and separately
changed map bytes; the shared library has a [provider baseline](../../../settings-catalog/validation/2026-10-18-native-sliders/README.md).

## Behavior and assembly

SettingsSliderRow uses the system continuous Slider when the range contains more than
20 step intervals. Binding writes round relative to the lower bound and clamp to the
caller range; accessibility Increase/Decrease uses exactly one supplied step. Sparse
scales (Fade1–16) retain the native stepped Slider. No public initializer, preference,
range, units, renderer algorithm or manually drawn control is added. Pointer/keyboard
rendering and focus stay native; keyboard parity with the previous stepped control
has not been demonstrated.

The app, catalog, release script and native trace runner now use swift-macos.sh.
It compiles with the active macOS SDK and explicitly supplies matching platform SDK
metadata to the linker. Deployment minimum is read from Package.swift; the supported
packages currently declare only macOS15. Explicit executable product builds verify
all Mach-O slices report the expected minos/SDK. No Python is added to release builds.
An explicit show-bin-path operation remains path-only. Release signing/notarization
and a fresh universal release were not run.

Host native_controls and catalog host_owned_binding/platform_availability are refreshed;
other stable claim IDs remain. The local UI dependency border is repinned. Previous
layout/Zoom/accessibility results remain on their original SDK/source baselines.
No formal contract or visual acceptance is inferred from structural checks.

## Actual observations and correction of prior diagnosis

- [Smooth SDK15 screenshot](smooth-sdk15.png) and [report](smooth-report.md): dense
  marks gone, sparse Fade marks retained. AX Density0→1%→0 and Speed0.43→0.44→0.43
  passed and restored. A short Density drag rounded to11% and was restored to0%.
  Keyboard Right did not establish focus or a value change; keyboard parity is unverified.
- The [nil-tick experiment](nil-tick-attempt.md) did not hide automatic marks and is
  not the implementation. Its failure was found in actual UI rather than build results.
- [Mach-O evidence](sdk-metadata.log): default Swift Build had emitted minos15/sdk15
  even while compiling against SDK27. Merely specifying --sdk did not correct it.
  The helper produces minos15/sdk27 for app and catalog without raising deployment.
- With identical UI source and corrected linked SDK, [actual SDK27 screenshot](native-sdk27.png)
  and [report](sdk-report.md) show the new native pill thumbs, tracks, switches and
  glass navigation. Apple documents automatic adoption in
  [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass),
  including the knob material changing during interaction. The owner also observed
  the glass thumb while interacting.
- **Known visual defect:** SDK27 also reproduces the persistent upper toolbar/blur
  overpaint in the actual app, obscuring Rain and part of Live Preview. The earlier
  fixture-only classification was incorrect outside the SDK15 compatibility profile.
  Both the initial and repeated actual capture confirmed it. It stays explicitly
  deferred by the owner; do not claim accurate heading visibility, a clean visual
  acceptance pass, default-on readiness or release readiness for this profile.

## Verification and limits

[App build](app-build.log), [catalog product build](catalog-build.log) with warnings-as-errors,
[16 settings tests](settings-tests.log), [lint](lint.log), [HC/SpecPM structure](structure.log)
and [source identities](identities.log) are separate evidence. Guard failure behavior
is recorded in [metadata guard probe](metadata-guard.log). Prior58frame/Zoom evidence
is historical; no new narrow compositor, full VoiceOver or physical macOS15 pass is claimed.
Tools: Swift6.4, SpecPM0.2.0, Hypercode SHA2566503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.
Known unresolved external capabilities remain draft dependencies.

Builds use verified TB5 UUID04B9F65E-894C-4A7C-B517-FC542E8D8E36 and distinct root/
nested-package scratch paths. No cache migration, CI watching or release.
Next: fix the actual SDK27 toolbar/safe-area composition before final visual rollout.
