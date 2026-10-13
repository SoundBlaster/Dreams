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
| RainOverlaySession.SessionLifetime / CaptureVisibility | Controller consumer | Folded into session | start/stop/resume, screenshot watcher | Capture-aware status corrected; pixels remain unproven |
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


### Capture visibility correction — 2026-10-13

User-authorized O1 fix: `dreams.overlay.session/requested_vs_presented` and
`capture_suspension` now distinguish active ownership from temporary capture
hiding. `rain_visible` is false while suspended; additive
`rain_suspended_for_capture` exposes the reason. The production observation
path and deterministic-time test path share the same transition implementation.
Native-overlay regression covers both backgrounds, clear grace/reset, stable
windows/expiry/sleep assertion, opt-in capture and stop while suspended. It
fails with the original visibility calculation. The full unit target passes.

Runtime/test baseline: `bd5d783e1a6051f663b94d78c26d0c683d3824ab`.
[Current identities](overlay-session/evidence/2026-10-13-capture-status/source-identity.json)
and [fresh validation](overlay-session/validation/2026-10-13-capture-status/README.md).
Session draft/package advance to draft.2; stable role/claim IDs remain unchanged.
Display/presentation/exit/glyph contracts and behavior remain applicable because
only capture observation/time factoring and session status output changed;
their original evidence remains historical. Physical picker detection and
pixel visibility are not established by these deterministic observations.
