# Dreams 0.1.12 release preparation — 2026-10-25

Base main: `909b538cafe43c4043036e5f77693c6b0566fc9f`, after merged
[PR #66](https://github.com/SoundBlaster/Dreams/pull/66). VERSION and both plugin
manifests advance together to 0.1.12. This preparation changes metadata and
documentation only: `Spec-ID: NO-SPEC-IMPACT`. Runtime, maps, requirements and
implementation bindings remain unchanged. Packaging remains an unrecovered boundary.

The [grid-clock evidence](../../../integration/2026-10-25/grid-clock/README.md)
preserves its production/test source identities, isolated timeout/measurements,
passing default and actual-Metal tests, and native UI automation limitation.
Neither these observations nor source/structure validation establish acceptance
of the final release binary. A 24-hour memory soak test was not performed.

`checks.json` records current metadata identities and local checks. The owner
authorized GitHub publication. The canonical `make release` pipeline uses the
verified per-worktree TB5 paths, committed fonts, a universal arm64/x86_64 Release
build, Developer ID with hardened runtime, and app/DMG notarization and stapling.

Final source/tree and binary hashes, Apple submission results, signature/stapling
and Gatekeeper checks, current-host launch scope and downloaded-byte verification
are published as [release-verification.json](https://github.com/SoundBlaster/Dreams/releases/download/v0.1.12/release-verification.json)
on [GitHub Releases](https://github.com/SoundBlaster/Dreams/releases/tag/v0.1.12).
Native mouse-click automation, clean-account and Intel-device runtime testing,
physical Apple TV performance and long-duration memory stability remain separate.
