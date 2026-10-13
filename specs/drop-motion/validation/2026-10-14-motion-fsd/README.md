# Drop motion FSD refresh — 2026-10-14

Current source `9cd68b861d4f201c8ff934e54af6d86f0a00839d`; [identities](../../evidence/2026-10-14-motion-fsd/source-identity.json).
The simulation is byte-identical to pre-FSD PR19; controls/defaults moved into page/config.
[Native settings](native.log), [unit model target](unit.log) and [12 tvOS simulator tests](tvos.log)
passed again. Earlier PRNG/Metal/screenshot evidence remains historical. Current checks do
not retest physical Apple TV or keyboard delivery. Draft claim IDs/accepted goals unchanged.
[Structure](structure.log) and [lint](lint.log) are separate schema/architecture checks.
