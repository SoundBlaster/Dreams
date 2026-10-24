# Dreams 0.1.10 release preparation — 2026-10-24

Metadata source `bc38ab210313ca496a9ee0787771824f8b766916` sets VERSION and both plugin manifests to 0.1.10.
The release includes merged [PR #56](https://github.com/SoundBlaster/Dreams/pull/56):
native settings open by default, with compatible --native-settings and an explicit
--legacy-settings override. The [native rollout evidence](../../../settings-host/validation/2026-10-24-native-default/README.md)
retains its original runtime/test/install identities; those tests are not relabeled
as binary acceptance for this version.

[Source identity](source-identity.json) pins release metadata, dependency lock,
release/build helpers, bundled resources and audited current host/catalog/motion
bindings. The audit also refreshed pre-existing catalog build-helper snapshot drift;
no library/catalog runtime changed. Version preparation changes no runtime algorithm,
map or contract requirement beyond the already merged default-route rollout. Stable
claims remain in force. Packaging itself remains outside recovered SpecPM coverage;
no new capability ID is invented for it.

Local metadata/plugin, lint/docs and HC/SpecPM checks are recorded in `checks.json`,
separately from distribution evidence. The owner authorized GitHub publication.
The established repository release entry point builds a universal arm64/x86_64 app
with the active SDK and existing deployment target, Developer ID and hardened runtime,
then notarizes/staples both app and DMG. Build/cache and release outputs use the
verified per-worktree TB5 root; source checkouts stay in place.

Final build/source identities, signatures, Apple submission status, stapling,
Gatekeeper, local installation scope and published-byte verification are retained
as [release-verification.json](https://github.com/SoundBlaster/Dreams/releases/download/v0.1.10/release-verification.json)
on [GitHub Releases](https://github.com/SoundBlaster/Dreams/releases/tag/v0.1.10).
This preparation record asserts source/metadata checks only. Downloadable binary
acceptance requires that separate final record; structural checks alone do not
establish it. Clean-account and Intel-device runtime testing remain distinct from
universal compilation and this host's checks.
