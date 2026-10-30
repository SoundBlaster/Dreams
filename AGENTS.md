# Dreams repository instructions

## Keep specifications current

Hypercode maps and SpecPM contracts are maintained project artifacts. Every
feature, bug fix and refactor includes specification impact assessment.
Start with [specification progress](specs/specification-progress.md), the
[architecture maps](specs/hypercode/README.md), and the affected SpecPM package.

1. Check the actual checkout, branch and changed source before reusing a map.
   Identify affected consumers, roles, profiles, claim IDs and parent assembly
   obligations before changing code.
2. Update affected current maps/contracts, implementation bindings and source
   identities alongside implementation. Recover a significant missing boundary;
   fold minor details into an existing contract. For a behavior-preserving change,
   record affected claim IDs and why the contract still applies instead of making
   cosmetic specification edits.
3. Preserve stable role/claim identities and accepted product requirements.
   Distinguish observed implementation, desired behavior and inferred obligations.
   Expose conflicts; never weaken a requirement to make code appear conformant.
   Newly recovered contracts stay descriptive drafts until explicitly accepted.
4. Preserve historical evidence and validation records. Add a new dated baseline
   for changed code; invalidate affected current claims and revisit dependent
   parent obligations. Do not relabel old test passes as evidence for a new SHA.
5. Run SpecPM validation and HC parse/validation for affected maps and profiles.
   Record commands, tool identity, source/map hashes, exit codes, diagnostics,
   remaining unknowns and acceptance state. Structural validity, source review,
   application tests, visual/device observations and acceptance are separate.
6. Update the shared progress/coverage record. Do not finish with affected
   current specifications knowingly stale. Unexplored subsystems remain explicit
   backlog, not implied coverage. Follow existing code verification requirements;
   specification-only work requires structural/docs checks, not an app launch.

## Required specification skills

Read the relevant installed SKILL.md instructions when applying a workflow:

- `legacy-to-specs`: coordinate impact, incremental recovery and coverage.
- `hypercode-architecture-map`: author/update/compare `.hc` and `.hcs` maps.
- `specpm-legacy-boundaries`: recover consumer contracts, source evidence,
  integration obligations and conflicts.
- `specpm-author-spec` and `specpm-review-spec`: author and review packages
  against the current authoritative RFC and executable validator.

Report a missing required tool/skill explicitly and preserve the artifacts.
Use current source/tool schemas rather than copying old skill examples blindly.
These skills govern descriptive artifacts; they do not install a policy engine
or make Hypercode/SpecPM executable application configuration.

## Dreams boundaries and working conventions

- Keep macOS overlay/display lifecycle, hooks/MCP, glyph tooling and tvOS
  profiles distinct. A check in one profile does not prove another.
- The browser glyph editor, local checkpoint database and installed app font
  are separate artifacts. JSON/checkpoint saving does not rebuild/install fonts.
- Preserve user checkpoints in `research/glyphs/stroke-library`, manual SVG/JSON
  files and unrelated agent work. Stage only task-relevant paths.
- Preserve glyph provenance and third-party licensing; do not claim film fidelity
  from structural checks. Changes to shared stroke forms affect every instance.
- Keep runtime algorithms and decisions in implementation. Adopt runtime policy
  libraries only when a code task calls for them and their integration is reviewed.
- Prefix shell commands with `rtk`; use `rtk proxy` for unsupported commands.
- Use the `no-wait` skill for long builds/tests and communicate meaningful changes.
- Existing checks are in `make help`. For specification structure use
  `make specs-check` with `hypercode` and `specpm` available (or explicit overrides).
- Preserve actual distinctions between local checks, CI, screenshots, physical
  devices and releases. A release/submission follows its own authorized scope.

## Local builds on the TB5 SSD

On Egor's macOS host, before local builds, tests, package resolution, or dependency
installs, read and apply the `tb5-build-cache` skill:
`/Users/egor/.codex/skills/tb5-build-cache/SKILL.md`.
Run its read-only `scripts/tb5_paths.py --project <package-or-workspace-root>`
preflight, then use the returned paths for supported build outputs and caches.
Keep build outputs separate for every checkout/worktree. Preserve the repository's
required build/check entry points and adapt their supported path overrides;
verify actual output locations instead of assuming an environment variable took effect.
If the expected SSD is unavailable, report the failure and continue independent
source work; do not silently fall back to the internal disk. Keep source checkouts
in place. This local routing rule does not apply to CI or other hosts and does not
authorize migrating or deleting existing artifacts. An explicit user-selected
build location takes precedence.
