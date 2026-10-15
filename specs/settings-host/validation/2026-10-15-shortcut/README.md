# Native stop-shortcut recording — 2026-10-15

Runtime `7ab5412d7cb0947208498f0a328b63f3134070e7`. [Current source/map identity](../../evidence/2026-10-15-shortcut/source-identity.json).
PR #28 was merged first; this stage starts from that main. Contracts remain descriptive drafts.

General now records/resets the stop shortcut with native buttons and inline feedback. One
window-scoped recorder serves both presentations. Esc cancels capture, not the rain;
plain/Shift-only keys keep capture active with guidance. Another window's events pass through.
Section changes, window close/key loss, app deactivation/hide, second activation and cleanup
cancel capture. Existing Carbon registration, persisted keys and menu update remain in the owner.
F13–F20 have readable display names. Advanced retains legacy access; native launch stays default-off.

## Evidence

- [63 local Swift/Metal tests](unit-metal.log) pass. Six new regressions cover readable function
  keys, window isolation, modifier/Esc semantics, single commit/observer cleanup, lifecycle,
  shared owner and a real controlled Carbon conflict followed by successful registration.
- [Build](build.log), [lint](lint.log), [actual-app keyboard observations](ui-check.md).
- [Screener SDK 0.2.0 hierarchy scenario](screener-hierarchy.log): 15 frames, completed session
  `E29CB4A3-05FD-49B3-948E-A12E2E5B823C`. [Timeline](timeline.jsonl), [hashes](frames.json).
  MCP sessions/timeline/frame inspected recording and narrow error states. The error state is
  an explicit presentation fixture; the Carbon test separately verifies the failure operation.
  Hierarchy images have black Metal regions, gray material and selection artifacts: these prove
  form state/layout, not actual compositor rain. CUA verifies the running application separately.
- [Commands/tool identities](runs.json), [HC/SpecPM structural validation](structure.log),
  [source/snapshot identity check](identity-check.log).

## Failures and limits retained

The [first full GPU run](unit-metal-initial.log) had one existing auto-column/1x crop mismatch;
[isolated crop recheck](crop-recheck.log) and the final complete run pass. The preview renderer
and crop test are unchanged; the intermittent cause is not established or claimed fixed.
An initial SCK scenario ended before recording frames. A sleep-only experiment completed but
had no live renderer ([failed log](screener-sck-failed.log)); it was reverted. This pass records
hierarchy evidence explicitly and does not claim a new successful SCK/compositor baseline.

Carbon rollback may still fail (existing overlay O2); this task preserves that limitation.
No fullscreen/display algorithm, TV, font/checkpoint or toolbar-blur change is included.
Old evidence remains historical, including prior successful material SCK captures.

All builds/tests above finished before the newly supplied TB5 routing rule. Subsequent TB5
preflight verified UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36 and checkout key
Dreams-36273a9c832f69b9. Existing internal `.build`/isolated app were preserved; no migration
or external rebuild is claimed. Remaining documentation checks use external Python/ruff caches.
