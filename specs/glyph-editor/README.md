# Glyph workspace contracts

Four SpecPM BoundarySpecs describe the browser editor at
`96fef7ad121cf9ba278eabd878c5179fd754a0cd`:

- [Editor](specs/editor.spec.yaml): parent assembly, editing/history, visual
  layers, transfer and optional local checkpoints.
- [Geometry](specs/geometry.spec.yaml): project validation, coordinate spaces,
  contour construction and materialized SVG.
- [Shared strokes](specs/components.spec.yaml): explicit shared-form editing,
  independent instance positions and detachment.
- [Checkpoints](specs/checkpoints.spec.yaml): canonical snapshots, optimistic
  head checks, disk index publication and loopback adapter.

All are **drafts reconstructed from source**, not accepted requirements or
proof that the UI is correct. [Claim/scenario matrix](matrix.md) distinguishes
bindings, assumptions, conflicts and unresolved owner decisions. Test files
are pinned as declared expectations only; no application tests or browser/device
runs were performed during this specification-only recovery.

[Source identities](evidence/2026-10-13/source-identity.json) bind full source snapshots and exact orientation excerpts to original repository paths and full-file hashes. Evidence copies
are immutable historical inputs, not alternate implementations to edit.
The [maps](../hypercode/README.md) are documentation; runtime code does not read
HC/SpecPM files. [Validation record](validation/2026-10-13/README.md) reports
actual structural checks and their limits.

## Reading the package

Scope is the glyph editor and its local API. Runtime browser storage/downloads,
Node and POSIX filesystem behavior are external capabilities. Their unresolved
validation warnings are retained rather than deleting integration obligations.
The macOS rain, hook/MCP semantics, tvOS clock, font build/adoption and film
fidelity are outside this package; their coverage is tracked in the
[shared progress record](../specification-progress.md).

Future changes must refresh the affected claims and source bindings. Preserve
these dated snapshots; add a new evidence/validation directory. A saved editor
checkpoint or SVG does not install a font in Dreams.
