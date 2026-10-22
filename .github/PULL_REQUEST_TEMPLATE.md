## Summary

- What changed?
- Link related issue/task (if any):

## Motivation

- Why is this change needed?
- What problem, gap, or user need does it address?

## Goals

- What should this PR achieve?
- What is intentionally out of scope?

## Changes

-
-

## Spec Evidence

For behavior or tooling changes, cite affected capability/claim IDs from `specs/`
and the relevant Hypercode roles/profiles. Start with
`specs/specification-progress.md` and `specs/hypercode/README.md`.
Link updated contracts, implementation bindings and dated validation where affected.
If a boundary is not covered yet, record the coverage gap rather than inventing an ID.
For a true no-impact change, use `Spec-ID: NO-SPEC-IMPACT` and provide a rationale.

Spec-ID:

Proposal-ID (if any):

Spec-Impact: behavior | schema | lifecycle | tooling | docs-only | no-impact

Spec-Rationale:

## Validation

- [ ] Tests added/updated for changed behavior (or explain N/A)
- [ ] Relevant local checks passed

Commands run:

```bash
# Examples; include only checks actually run:
# make lint
# make test-unit
# make specs-check
```

Results:

- Tested source revision and platform/profile:
- Results and evidence links:
- Skipped checks and remaining unknowns:

Distinguish local tests, CI, screenshots/recordings, physical-device observations
and release verification. Simulator results do not establish Apple TV performance.
For performance changes, include the scenario, device, build identity and before/after
metrics. Documentation-only changes need relevant docs/structure checks, not an app launch.

## Risks / Notes

- Backward compatibility impact:
- Migration/config changes required, including feature-flag defaults:
- Known limitations:

## Checklist

- [ ] PR title clearly describes the change
- [ ] Scope is focused and minimal
- [ ] Documentation updated (or N/A)
- [ ] Specification impact assessed; affected maps/contracts/bindings/evidence updated (or no-impact rationale provided)
- [ ] Validation identifies the tested revision and platform/profile; historical passes are not presented as current evidence
- [ ] macOS overlays/settings, agent integrations, glyph tooling and tvOS evidence remain scoped to their affected consumers
- [ ] Glyph checkpoints, provenance and third-party licenses preserved (or N/A)
- [ ] Temporary or intermediate paths are scoped to the current run/task where relevant
- [ ] No secrets or sensitive data added
