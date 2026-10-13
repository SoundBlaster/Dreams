# Structural validation — 2026-10-13

Specification recovery only; application/editor runtime code was not changed.
Source baseline and snapshots: [source identity](../../evidence/2026-10-13/source-identity.json).
Actual commands, cwd, exit codes and complete stdout/stderr: [runs](runs.json).
Executable/schema identity: [tools](tools.json).

## Results

- Application HC parse and validation: exit 0.
- Glyph editor HC parse and validation: exit 0 for default local-server and
  `mode=standalone` profiles. These maps currently have no HC `@contract` rules;
  success establishes supported syntax/cascade checks, not domain invariants.
- [SpecPM result](specpm.json): **0 errors, 8 warnings**, `warning_only`, exit 0.
  All warnings are `required_capability_unresolved` in the current MVP validator.
- Pinned full source/map snapshots were compared byte-for-byte; coarse
  orientation excerpts match their recorded line ranges. Full-file SHA-256
  identities are retained for all examined inputs. Makefile's additive spec-check
  target is identified as a working-tree delta; runtime inputs match the base.
- Markdown links and Git whitespace checks are recorded in this directory.

## Warning interpretation

Five warnings reference internal child capabilities: geometry (three uses),
components and checkpoints. They are declared by this package, but the current
MVP validator still reports required-capability resolution as unresolved.
Three warnings identify real external prerequisites: Node execution, POSIX
filesystem behavior and browser editor-host APIs. Neither manifest declarations
nor an HC map prove that a runtime provides these dependencies. The obligations
remain in the contracts and review matrix.

## Verification limits

No app build, application tests, browser screenshots, physical-device checks,
font build/install, runtime security audit or release was performed for this
specification-only task. Existing test files are source-level expectations;
previous feature-development runs are historical and not reclassified here.
The Hypercode binary is identified by digest; its build revision is unknown.
SpecPM 0.2.0 uses the inspected executable Python validator, not the older skill
skeleton for effects/provenance. All recovered requirements retain draft status.

## Re-run from the repository root

With both tools available on PATH:

```sh
rtk proxy make specs-check
```

If Hypercode is only available as a local build, set its executable explicitly:

```sh
rtk proxy make specs-check HYPERCODE=/absolute/path/to/hypercode
rtk proxy python3 scripts/check-docs.py
rtk proxy git diff --check
```

A new code/map baseline needs new evidence and a new validation record;
do not overwrite this historical result to imply validation of changed code.
