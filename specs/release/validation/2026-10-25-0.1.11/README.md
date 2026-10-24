# Dreams 0.1.11 release preparation — 2026-10-25

Base main: `76378005de72b6ecf0f066ae1f0210b55a36aea9`, after merging PRs #59–64.
VERSION and the Claude/Codex plugin manifests advance together to 0.1.11.
This preparation changes release metadata only; existing runtime, source bindings,
Hypercode roles/profiles and SpecPM claims remain applicable without modification.
`Spec-ID: NO-SPEC-IMPACT`. Packaging itself remains outside recovered coverage.

The source identity and local metadata/structure checks are recorded in
`checks.json`. Historical app, Metal, simulator and UI observations keep their
original source and profile; they do not establish acceptance of the new binary.
Performance acceptance and physical Apple TV observations remain separately scoped.

The owner authorized GitHub publication. The canonical `make release` pipeline
builds a universal arm64/x86_64 macOS app, signs with Developer ID and hardened
runtime, and notarizes/staples both app and DMG. Outputs/caches use the verified
per-worktree TB5 location. The committed fonts are packaged without rebuilding
user glyph checkpoints.

Final source/binary identities, Apple submission results, signature/stapling and
Gatekeeper checks, local launch scope and published-byte verification are retained
in [release-verification.json](https://github.com/SoundBlaster/Dreams/releases/download/v0.1.11/release-verification.json)
on [GitHub Releases](https://github.com/SoundBlaster/Dreams/releases/tag/v0.1.11).
This preparation record asserts metadata/structural checks only. Clean-account,
Intel-device runtime and physical Apple TV testing are separate evidence boundaries.
