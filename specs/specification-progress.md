# Dreams specification progress

Goal: maintain compact architecture maps and consumer contracts alongside code
changes. Initial scope: repository maintenance rules and the browser glyph
editor on `96fef7ad121cf9ba278eabd878c5179fd754a0cd`. All recovered contracts are **descriptive drafts**;
formal acceptance and runtime conformance remain separate owner decisions.

## Coverage — 2026-10-13

| HC role/path | Consumer / profile | Contract or disposition | Baseline / evidence | Next action |
| --- | --- | --- | --- | --- |
| Dreams | Contributors | Coarse orientation only | application.hc/hcs; source orientation | Expand by consumer need |
| DesktopApplication | macOS user / overlay, transparent, multi-display | Partial: overlay session recovered, other settings UI unexplored | Merged-main source 1ce1947 | Review overlay backlog |
| DesktopApplication.RainOverlaySession | Interactive/agent × opaque/transparent | dreams.overlay.session | Pinned source; structural checks linked below | Review O1–O6 |
| RainOverlaySession.DisplayTargets | User / saved display selection | dreams.overlay.displays | targets/load/save | Physical clamshell/reconnect still unobserved |
| RainOverlaySession.Presentation | User / windows and focus | dreams.overlay.presentation | reconcile/close, panel config | Verify focus/OS resource failures |
| RainOverlaySession.ExitInput | User / local Esc, button, global hotkey | dreams.overlay.exit | Callbacks, recording, Carbon adapter | Review rollback/status O2 |
| RainOverlaySession.SessionLifetime / CaptureVisibility | Controller consumer | Folded into session | start/stop/resume, screenshot watcher | Status ≠ pixel visibility (O1) |
| RainOverlaySession.Renderer | Presentation consumer | Opaque required capability; unexplored rendering contract | Constructor/configuration only | Recover actual renderer contract separately |
| AgentIntegrations | Codex/Claude hooks and MCP | Unexplored | Package/plugin entrypoints only | Recover event/privacy/lifecycle obligations |
| GlyphToolchain.FontBuild | Font contributor / release | Unexplored | pipeline.py orientation only | Recover adoption/build/install boundary |
| GlyphEditor | Glyph contributor / local-server and standalone | dreams.glyph.editor | Pinned source + source review; structural results linked below | Review parent obligations and async saves |
| GlyphEditor.EditingSession | Contributor | Folded into editor | edit/restore/endDrag | Review browser/gesture scenarios |
| GlyphEditor.Geometry | UI, Node validator, SVG consumer | dreams.glyph.geometry | Pinned model | Review coordinates and metric compatibility |
| GlyphEditor.SharedStrokes | Contributor, multiple glyphs | dreams.glyph.components | Pinned editor/model | Review clipboard identity and shared-edit scope |
| GlyphEditor.VisualGuides | Contributor | Folded into editor | References, rulers, presets, trace | Browser-local recovery and portability remain limited |
| GlyphEditor.ProjectTransfer | JSON/SVG consumer | Folded into editor | loadProject/save/export | Browser receipt is not saved-file evidence |
| GlyphEditor.CheckpointLibrary | Editor tab / local disk | dreams.glyph.checkpoints | Pinned Python/Node adapter | Review concurrency/crash limits |
| GlyphEditor.EditorBuild | Developer | Folded into editor | build + pipeline.toml | No font adoption claim |
| TelevisionApplication / clock | Apple TV user | Integrated PR #8; coarse orientation, contract unexplored | Current rebased source 691d94b; simulator tests separate | Recover clock/settings contract on its own baseline |

Maps: [architecture index](hypercode/README.md). Contracts, claim origins,
source bindings, scenarios and unresolved decisions:
[glyph editor](glyph-editor/README.md), [matrix](glyph-editor/matrix.md).
Validation: [2026-10-13](glyph-editor/validation/2026-10-13/README.md).

## Maintenance cycle

Before implementation, identify affected roles, profiles and stable claim IDs.
After implementation, update current contracts/bindings and add a new evidence
baseline. For a change preserving a contract, record its IDs and justification
here rather than rewriting unchanged requirements. Preserve old records as
historical; a successful old run cannot prove a new source revision.

Initial recovery is documentation/tooling only: no application/editor behavior,
user glyph/checkpoint database, font resources or acceptance state changed.
Previous local test/browser observations from the editor development remain
historical; this recovery does not relabel them as fresh execution evidence.

## Overlay recovery — 2026-10-13

PRs #15 and #16 are merged; this pass starts from main `1ce194748720e40e1eb9737e63bb37797c5840b1`.
[Overlay package](overlay-session/README.md), [claim/scenario matrix](overlay-session/matrix.md),
[structural validation](overlay-session/validation/2026-10-13/README.md).
Four drafts cover session assembly, display policy, presentation/focus and exit input.
Current application map gains a DesktopApplication.RainOverlaySession detail;
glyph editor role/claim IDs and source bindings remain unchanged. Existing
`dreams.glyph.*` contracts still apply: this pass changes docs and adds overlay
validation to Makefile only, leaving glyph implementation inputs unchanged.
The historical application-map snapshot in the glyph package remains preserved.

Observed review items include status versus capture suspension, hotkey rollback
reporting, conditional focus recovery and capture-tool limits. No implementation
fixes, app tests, live windows, physical keys or topology changes were performed.
Next useful boundary: MCP controller/publisher authority and stop/prepare/resume
composition; renderer, hook privacy and tvOS remain separately scoped backlog.

### PR #17 review correction — 2026-10-13

`dreams.overlay.exit/button_visibility` now explicitly describes the tracked
pointer flag, its false initial state and its mouseMoved/mouseExited updates.
A stationary cursor over Exit at presentation does not guarantee that the
button stays visible. Matrix O7 preserves that source-derived limitation;
this changes a descriptive draft, not an accepted product requirement or
runtime code. Source bindings and HC profiles are unchanged.
[Review validation](overlay-session/validation/2026-10-13-review-p2/README.md)
is separate from the preserved initial baseline.

## PR #8 FSD integration — 2026-10-13

Rebased FSD/tvOS branch on main 85e3aee without textual conflicts. Current production
source 691d94b65eb8fd1687b09cef7ff4f6f5c2776c83 relocates macOS code into app/pages/features/entities/shared.
[Overlay bindings and fresh checks](overlay-session/validation/2026-10-13-fsd/README.md)
refresh dreams.overlay.* source identities while preserving claim/role IDs and draft status.
Settings recording/cleanup ownership moves to SettingsPageController retained by
DreamsDelegate; its termination path still uninstalls Carbon registration and stops rain.
Display/overlay/renderer behavior retains the same implementation bodies. New settings
and tvOS leaves are coarse orientation only: their full consumer contracts remain backlog.
Glyph editor contracts/implementation are untouched; their historical application-map
snapshot remains preserved. PRs #18–20 are not included in this source baseline.
