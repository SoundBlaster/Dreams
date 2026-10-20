# Dreams 0.1.9 release preparation — 2026-10-20

Metadata source `b707355d815615ad61f7aceb71b9aefdf8e4d8ae` sets VERSION and both plugin manifests to0.1.9.
[Identity](source-identity.json) pins the release metadata and verifies all60 host
and25 catalog source/map entries against this checkout. Other subsystem baselines
remain historical and are not asserted current by this release audit.

The version change preserves existing roles/claims and explicit native-settings
opt-in. Runtime tests from previous commits retain their original scope; structural
checks do not establish VoiceOver speech, hover behavior or cross-platform acceptance.

[Release log](release.log) records a universal SDK27/minos15 build, hardened runtime
Developer ID signature, Accepted Apple notarization and stapling for app andDMG,
and Gatekeeper acceptance. [Plugin checks](plugins.log), [structure](structure.log)
and [documentation links](docs.log) record separate checks on this metadata baseline.
The repository release script was copied to /tmp with only checkout root, build/cache
paths and output destination adapted to verifiedTB5; no build/signing/notary checks
were removed. Source checkout and prior local outputs were preserved.

DMG SHA256: `697e99a0fef4fab20f079be9929b2a8fcc8960ee35aeb2f1ce66136bd9ddd9df`.
GitHub publication and remote digest verification follow successful PR checks and
merge; this preparation record does not claim they already happened.
