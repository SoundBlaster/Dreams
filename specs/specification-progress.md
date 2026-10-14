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
| RainOverlaySession.Renderer | Presentation consumer | Partial: motion and search recovered; other rendering unexplored | Renderer/configuration plus drop-motion detail | Shader/atlas remain unexplored |
| RainOverlaySession.Renderer.DropMotion | macOS rain viewer / off or decelerating | dreams.rain.drop_motion | Current 3a4ad94 search baseline; prior braking evidence preserved | Review terminal-speed assumption; other renderer behavior unexplored |
| SettingsCatalog | Contributors / standalone macOS app | dreams.settings.catalog | Native-host integration baseline; independent catalog fixtures | Interactive catalog acceptance |
| DesktopApplication.SettingsPage | macOS user / legacy or native launch | dreams.settings.host | Default-off native routing and shared owner; local tests + Screener 0.2.0 | Keyboard/VoiceOver, compositor acceptance; embedded preview next |
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

Current capture-status FSD refresh: [2026-10-14 validation](overlay-session/validation/2026-10-14-capture-fsd/README.md). Suspended status is false without owned overlays.

## Drop deceleration — 2026-10-13

User-requested opt-in feature: unchanged entry speed, one negative-acceleration
control. [Drop-motion contract](drop-motion/README.md) recovers head timing,
stationary fading tail, event duration and controller/renderer assembly.
Renderer.DropMotion is the new detail; other renderer and tvOS contracts remain
unexplored. Existing display/exit/session lifecycle and glyph contracts keep
stable IDs and still apply: the source changes add saved visual tuning and
renderer propagation without altering their lifecycle/input ownership paths.
Initial overlay snapshots remain historical; current motion source/map identities
and runtime results are in the new package. PR #18 capture status is independent.

Check coverage includes analytic kinematics, invalid tuning, legacy parity,
frame subdivision, sequential fading, full density, event expiry and native UI
persistence. Terminal speed 20%, range -120…0, default -12 and next-packet tuning
are explicit implementation choices, not inferred user-specified values.
Next boundary: renderer shader/atlas composition, when changes require it.

Current motion FSD source and checks: [2026-10-14 validation](drop-motion/validation/2026-10-14-motion-fsd/README.md). Historical snapshots remain unchanged.

## PR stack integration — motion-stack — 2026-10-14

Source `23ac3667ab1e0597d9f18e45c69dcb3859c10f89` includes merged capture-status PR18 and the current drop layer.
[Session integration](overlay-session/validation/2026-10-14-motion-stack/README.md) and
[drop integration](drop-motion/validation/2026-10-14-motion-stack/README.md) refresh current source bindings.
Affected session status/capture, motion timing/tuning and settings assembly claims keep
their stable IDs and draft acceptance. Historical passes are not evidence for this revision.

## Search occupancy — 2026-10-13

Renderer.GlyphSearch is recovered in the existing rain-simulation package as
`dreams.rain.search_occupancy`; [contract/claims](drop-motion/search-matrix.md) and
[current checks/identities](drop-motion/validation/2026-10-13-search/README.md) use source 3a4ad94.
This implements the user's corrected goal: a minimum simultaneous share, not starts/second.
Motion claim IDs remain stable; opt_in comparisons now hold the new mutation policy constant.
The earlier legacy whole-state random-sequence sample is historical and not reused as proof.
Display/exit/session and glyph editor contracts retain their IDs and obligations: changes
only add visual tuning and simulation scheduling, without altering display/input ownership.
Renderer Population/Quota/BurstLifecycle/Tuning are folded into the search contract;
shader/atlas, agent event acquisition, tvOS and glyph editor adoption remain unexplored here.
Native AppKit control/persistence, Screener SDK/MCP appearance and pure model tests are
separate evidence; draft status and remaining parent integration assumptions are explicit.

Current search FSD/P2 source and checks: [2026-10-14 validation](drop-motion/validation/2026-10-14-search-fsd/README.md). Quota/count caching and timestamp queues preserve visible-state digests; prior evidence remains historical.

## PR stack integration — search-stack — 2026-10-14

Source `a22e44ace8f08fb10650d9b15a37c8183062fd0d` includes merged capture-status PR18 and the current drop layer.
[Session integration](overlay-session/validation/2026-10-14-search-stack/README.md) and
[drop integration](drop-motion/validation/2026-10-14-search-stack/README.md) refresh current source bindings.
Affected session status/capture, motion timing/tuning and settings assembly claims keep
their stable IDs and draft acceptance. Historical passes are not evidence for this revision.

## Native settings catalog — 2026-10-14

Source `0ddcc4f62dba1a264bbacb567b058931a56e4bec` adds the standalone catalog and UI composition package.
[Catalog contract and limits](settings-catalog/README.md) and
[fresh validation](settings-catalog/validation/2026-10-14/README.md) cover this first stage.
Production Sources/Dreams, Package.swift, tvOS and glyph implementation are unchanged.
Existing dreams.overlay.*, dreams.rain.* and dreams.glyph.* claim IDs still apply;
there is no changed production implementation to repin. The application HC map adds
a sibling SettingsCatalog role. Desktop SettingsPage remains unchanged and its full
consumer recovery stays backlog. Flagged settings adoption, shared live bindings,
embedded Metal and whole-window glass are desired later stages, not current evidence.

## Native settings host — 2026-10-14

Current implementation source: `f0b7f0f3dab4d1c22dce4f9cc7273984d24e33b6`.

The default-off `--native-settings` route adopts the UI library without the catalog
executable. [Host contract and limits](settings-host/README.md) recover launch
routing, native bindings, legacy access and lifecycle. `--legacy-settings` overrides
the opt-in; no saved flag exists. Both windows share DreamsController and one timer.
Screener SDK/test reader advances explicitly to 0.2.0; optional compositor capture
stays test-only and requires existing authorization.

Affected `dreams.overlay.session` lifecycle/cleanup/reopen and `dreams.rain.drop_motion`
/ `dreams.rain.search_occupancy` tuning claims retain stable IDs. Controller changes
announce existing completed preference/renderer effects; the settings page routes
presentation and synchronizes controls. No motion/search/display/exit algorithm is
changed. Current identities and fresh structural records replace affected current
bindings; old physical/pixel/benchmark passes are not relabeled for this source.

`dreams.settings.catalog/independent_host` now distinguishes a standalone catalog
from library adoption, superseding the stage-one manifest observation. Catalog
fixtures remain independent of production. Glyph contract/source/checkpoint data
and tvOS are unchanged and retain their separate baselines. Native input and exact
compositor appearance remain unobserved under the locked Mac. Embedded rain, glass
and full shortcut parity are next-stage work, not current implementation coverage.

### PR #22 UI-library border correction — 2026-10-14

`dreams.settings.host/native_controls` now declares its local `dreams.settings.ui`
prerequisite, with manifest/consumed-slider files in the binding border and
[new current source identity](settings-host/evidence/2026-10-14-ui-border/source-identity.json).
The catalog contract exposes that existing library interface as a secondary
capability, without requiring its executable. The previous host identity and
runtime passes remain preserved; app code and all other claim IDs are unchanged.
[Fresh structural/docs/identity checks](settings-host/validation/2026-10-14-ui-border/README.md)
do not imply a new application or compositor test run.

## Release 0.1.6 — 2026-10-14

PRs #21 and #22 are merged in main. Production source files and local UI
dependency hashes match the reviewed native-host baselines; release preparation
changes only VERSION and the two plugin version fields. Existing overlay/rain,
glyph and settings claim IDs/bindings remain applicable: no runtime algorithm,
control or local UI source is changed by the release version bump.

The release's ordinary launch uses the legacy settings route. The native host
requires the explicit `--native-settings` argument; no stored feature flag or
ordinary menu enables it. Interactive native/compositor acceptance remains
pending and is not a claim of this release. Universal build/signing, notarization
and published-asset validation are separate release evidence.
