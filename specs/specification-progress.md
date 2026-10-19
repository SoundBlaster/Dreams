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
| RainOverlaySession.ExitInput | User / local Esc, button, global hotkey | dreams.overlay.exit | [Current retry fix](overlay-session/validation/2026-10-15-shortcut-retry/README.md) | Review rollback/status O2 |
| RainOverlaySession.SessionLifetime / CaptureVisibility | Controller consumer | Folded into session | start/stop/resume, screenshot watcher | Capture-aware status corrected; pixels remain unproven |
| RainOverlaySession.Renderer | Presentation consumer | Partial: motion, head appearance, search and pulse recovered; other rendering unexplored | Renderer/configuration plus drop-motion detail | Shader/atlas remain unexplored |
| RainOverlaySession.Renderer.DropMotion | macOS rain viewer / off or decelerating | dreams.rain.drop_motion | Current 96bda65 [shortcut retry integration](drop-motion/validation/2026-10-15-shortcut-retry/README.md); prior braking evidence preserved | Review terminal-speed assumption; other renderer behavior unexplored |
| RainOverlaySession.Renderer.DropMotion.HeadAppearance | macOS rain viewer / opaque or transparent | dreams.rain.head_visibility | Current 96bda65 [shortcut retry integration](drop-motion/validation/2026-10-15-shortcut-retry/README.md); model and offscreen GPU checks | Physical desktop compositor acceptance remains unobserved |
| RainOverlaySession.Renderer.GlyphPulse | macOS glyph viewer / opaque, transparent, off | dreams.rain.glyph_pulse | Current 96bda65 [shortcut retry integration](drop-motion/validation/2026-10-15-shortcut-retry/README.md) | Physical desktop compositor acceptance remains unobserved |
| SettingsCatalog | Contributors / standalone macOS app | dreams.settings.catalog | Current bc7294f [glass panels](settings-catalog/validation/2026-10-19-liquid-glass/README.md); independent fixtures | Interactive catalog acceptance |
| DesktopApplication.SettingsPage | macOS user / legacy or native launch | dreams.settings.host | Current d93aca4 [sidebar rows/preview alignment](settings-host/validation/2026-10-19-sidebar-rows/README.md); grouped forms, shared owner and default-off routing | Owner visual acceptance; narrow compositor and keyboard/VoiceOver |
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

## Drop head visibility correction — 2026-10-14

Runtime d3b962a7402e56f82f775be76c6e3fb068efacbe preserves motion/search schedules and stable `dreams.rain.drop_motion` /
`dreams.rain.search_occupancy` claim IDs while updating their affected source identities.
`dreams.rain.head_visibility` recovers the significant missing head-appearance boundary
in the existing rain package. The HC detail adds HeadAppearance without changing established roles.
[Current identity and regression/GPU evidence](drop-motion/validation/2026-10-14-head/README.md)
separate default brightness/no-glow macOS pixels, model timing, tvOS Simulator checks and structural validity.

The fixed 0.11-second head flash could expire during a slower braking step, and random
trail ink multiplied head highlighting by 0.2. Gaps could hide the head entirely. The current
head now stays pale through its flight step, then fades after leaving the bottom; gaps
render transiently without entering the stationary trail or search population. Search
settlement remains unhighlighted; alpha fade and expiry remain unchanged.

The earlier search rewrite removed standalone random mutation flashes; those are not restored
as search-completion flashes. Shared `headIntensity` also changes TV highlight duration,
while TV retains its existing ink-based tint. Twelve Simulator tests pass; physical TV and
desktop compositor acceptance remain unobserved. Overlay session/display/exit, settings host,
fonts and glyph checkpoints retain their unchanged source bindings and obligations. The
overlay HC renderer-coverage property is refreshed; other rendering remains explicit backlog.

### PR #24 coverage review correction — 2026-10-14

The DropMotion coverage row now names current runtime `d3b962a` and links its head
validation instead of the obsolete `3a4ad94` baseline. HeadAppearance has an explicit
coverage row with physical compositor acceptance still outstanding.
[Fresh documentation/structural verification](drop-motion/validation/2026-10-14-head-review/README.md)
does not relabel the existing runtime tests as new review-commit evidence. Code, maps,
claim IDs, source snapshots and draft acceptance remain unchanged.

## Release 0.1.7 preparation — 2026-10-14

The staged release combines PR #24 runtime `d3b962a`, coverage correction `fb93d69`
and the merged 0.1.6 version baseline. Preparation changes only VERSION/plugin
metadata and this progress record; all current head/motion/search source and map
hashes match their pinned evidence. Stable claim IDs and draft acceptance remain.
Release publication follows the fix merge. Default launch retains legacy settings;
the native host still requires explicit `--native-settings`. Signed universal build,
Apple notarization and published-asset verification are separate release evidence.

## Glyph brightness pulse — 2026-10-14

Runtime `74b57fa` adds the macOS `dreams.rain.glyph_pulse` draft boundary and HC detail.
Independent whole-glyph exposure follows real time, affects ordinary ink/words/halo, and
retains pale heads, core alpha, search quota, motion and expiry guards. The saved strength
slider is available in legacy settings and the explicitly opted-in native host; default
30 percent, 0 disables. Periods 1.33–4 seconds and gain floor 0.35 at full strength are
implementation choices rather than film-fidelity claims.

[Current rain identities and validation](drop-motion/validation/2026-10-14-pulse/README.md),
[overlay assembly](overlay-session/validation/2026-10-14-pulse/README.md) and
[settings host](settings-host/validation/2026-10-14-pulse/README.md) repin changed sources/maps.
Stable motion/search/head, overlay display/presentation/exit and native ownership/range/flag
claim IDs retain their meanings; old results remain on their original baselines.
Forty-seven local Swift/GPU tests pass on this runtime, including zero/invalid tuning,
asynchronous phases, native/legacy persistence, on/off alpha comparison and pale-head regressions.
The pure exposure helper sample takes approximately 0.86ms per maximum-grid frame locally;
this is not a full rendering FPS guarantee. No tvOS source, glyph/font/checkpoint, hook
authority or native launch flag changes occur. Physical compositor acceptance remains unobserved.

## Continuous drop head trials — 2026-10-14

Runtime `ab6290c47f24c43a7ce7e6fdd71272ae6abb34c7` adds head-only displayed glyph trials at 0.035 simulation seconds.
The early `93f5069` version used only new-row glyph writes for heads and excluded them from trail search;
this is a new explicit presentation rule, not evidence that a continuous loop was deleted.
The trials remain visible at zero trail search and during braking, without mutating stored ink or quota.
The HeadAppearance role and existing visibility claims stay stable; head_trials is folded into that draft.

[Current source/map identities and checks](drop-motion/validation/2026-10-14-head-cycle/README.md)
record 52 passing local tests and a negative outline regression on the exact prior renderer bytes.
Motion/search/pulse, native setting ownership/ranges/flag and overlay lifetime/display/exit claims retain
their meanings; [overlay](overlay-session/validation/2026-10-14-head-cycle/README.md) and
[settings](settings-host/validation/2026-10-14-head-cycle/README.md) record the unchanged assembly.
All older source/test evidence remains historical. Both background profiles are covered offscreen;
physical compositor/TV acceptance remains unobserved. No font/checkpoint or new preference is added.

## Release 0.1.8 preparation — 2026-10-15

PR #26 combines the pulse and continuous-head runtime baselines; both pinned commits remain
reachable in main through the merge commit. Release preparation changes only VERSION, the
two plugin version fields and this progress record. Current implementation/map hashes match
the 2026-10-14-head-cycle identities. Stable claim IDs and draft acceptance remain unchanged;
metadata checks and release artifact verification are separate from historical runtime tests.
The owner observed the local macOS animation before authorizing this release. That observation
does not establish new physical TV, topology or complete compositor acceptance. The native
settings host remains an explicit --native-settings opt-in; default launch uses legacy settings.

[Preserved 0.1.8 release-preparation commands, tools, identities and diagnostics](release/validation/2026-10-15-0.1.8/README.md) distinguish metadata checks from runtime, CI and signed publication evidence.

## Window-local native live preview — 2026-10-15

Runtime `1c8ba19844fffad464ac7dd7dfce8aba7dac0bb7` from main 6efbbeb; the isolated codex/native-live-preview checkout preserves user glyph work.
SettingsPage.NativePresentation.LivePreview now shares production tuning through a separate renderer/clock,
with local playback, Reduce Motion handling, visibility/resource cleanup, Retry and adaptive layout.
The ordinary launch stays legacy and the explicit native flag remains default-off. No full-window glass yet.

[Host checks/limits](settings-host/validation/2026-10-15-preview/README.md), [rain integration](drop-motion/validation/2026-10-15-preview/README.md)
and [overlay integration](overlay-session/validation/2026-10-15-preview/README.md) pin the current sources/maps. Stable role/claim
IDs remain; preview constraints extend the existing descriptive host draft. The consumed UI package border now
includes SettingsPreviewRegion; catalog implementation/source and its independent-fixture obligations are unchanged.

55 local tests pass; 11 exact-window SCK frames have rendered Metal content. CUA verifies the actual app in light/dark,
Pause/Play, columns and minimize/restore. SwiftPM/SCK images retain toolbar/slider artifacts absent in the actual app;
they are not a clean visual acceptance baseline. MacOS 15, complete accessibility/input parity, physical TV/fullscreen
compositor and display topology remain unobserved. Historical evidence is not relabeled for this source.

## 100% preview scale — 2026-10-15

Runtime `4973f2576232fab2c33398e6c49ce461cd5ad95d` replaces fit-to-panel with a hosting-display-sized viewport cropped by the preview drawable.
The user requires 100% glyph/grid size and explicitly defers the blur overlap. preview_scale is folded into
SettingsPage.NativePresentation.LivePreview; other stable host/rain/overlay IDs keep their requirements.
[Current baseline](settings-host/validation/2026-10-15-scale/README.md) records 56 passing tests, four byte-exact GPU crop
cases (auto/manual × 1x/2x), actual-app CUA observation and fresh structural/identity checks. Historical SCK
artifacts stay historical; no new capture acceptance is claimed. Display/backing changes refresh previews,
but physical monitor-move behavior remains unobserved. TV, glyph/checkpoints and blur implementation are untouched.

## Native rain and material composition — 2026-10-15

Runtime `3910ebf93779f8da807bf361f89873092db03b7d` retains one Metal surface across adaptive
layout changes, behind grouped forms and a clear preview region. A shared system material
panel is now a catalog/UI-library primitive. macOS 26 uses system navigation background
extension and a glass playback button; macOS 15 keeps the standard material/button fallback.
The 100% display-scale, playback/lifetime and default-off constraints remain.
The user chose this next stage and observed the shown result; formal spec acceptance remains draft.

[Host checks](settings-host/validation/2026-10-15-materials/README.md) distinguish 57 local tests,
13 Screener SDK/SCK frames inspected through MCP, actual-app CUA interaction, and structure.
Known toolbar blur is deliberately deferred; slider/capture artifacts are recorded.
Reduce Transparency and physical macOS 15 accessibility acceptance remain unobserved.
[Catalog](settings-catalog/validation/2026-10-15-materials/README.md),
[rain](drop-motion/validation/2026-10-15-materials/README.md) and
[overlay](overlay-session/validation/2026-10-15-materials/README.md) identities are refreshed.
All earlier evidence is historical; no TV, glyph/font, hook or fullscreen algorithm changes.

## Native stop-shortcut recording — 2026-10-15

Runtime `7ab5412d7cb0947208498f0a328b63f3134070e7` follows merged PR #28. General gains native Change/Cancel/Default actions;
Advanced retains legacy access. Shared ShortcutRecording is a small new HC child of SettingsPage,
with window scope and navigation/focus/lifecycle cancellation. Stable host `explicit_legacy_access`
and `overlay_exit` claims describe the authorized migration; `shortcut_recording` folds its details
into the existing host contract. Overlay `hotkey_recording` and source identities are refreshed.
Carbon rollback O2 remains unresolved. Other overlay/rain claims keep their meanings, with source
snapshots repinned for the shared settings consumer; no renderer, TV or glyph behavior changes.

[Host validation](settings-host/validation/2026-10-15-shortcut/README.md) separates 63 passing Swift/Metal tests,
actual app CUA keyboard checks, 15 Screener hierarchy frames and structural checks. It preserves
an intermittent earlier crop failure and unsuccessful SCK trials without relabeling them as passes.
[Overlay assembly](overlay-session/validation/2026-10-15-shortcut/README.md) and
[rain tuning consumer](drop-motion/validation/2026-10-15-shortcut/README.md) remain descriptive drafts.
The unchanged catalog/UI package keeps its prior material baseline. New settings remain default-off.

## Compact native shortcut layout — 2026-10-15

Runtime `0eb39ff4826f71f7739100671f8faf889e718a88` changes only General's presentation. Native shortcut value/actions
share one adaptive row with caption-sized guidance; recording/errors replace ordinary help.
Host native_controls/shortcut_recording/overlay_exit/one_settings_owner/default_off/material_composition
and rain glyph_pulse settings assembly claims remain applicable: callbacks, recorder,
registration, storage, preview and NativeAppearanceForm are unchanged. HC source bindings
continue to point to the same file and roles; no new boundary or cosmetic map edit is needed.
[Current host baseline](settings-host/validation/2026-10-15-shortcut-compact/README.md) and
[rain source identity](drop-motion/evidence/2026-10-15-shortcut-compact/source-identity.json) supersede the
corresponding shared-file hashes. Overlay/catalog/glyph/TV sources retain their prior identities.
Old runtime results are not reused as checks for this source. Draft acceptance remains unchanged.

## Startup shortcut retry P2 — 2026-10-15

Runtime `96bda65c685ca4759e93e7fde95056b97fc237f9` restores Carbon installation on a settings retry after startup conflict.
The regression fails on prior code at event dispatch and all 16 settings tests pass after the fix.
Stable host shortcut_recording/overlay_exit and overlay registration_failure/callback_lifetime
claims clarify full retry installation. SettingsPageController's rain consumers are repinned;
other runtime behavior and HC maps remain unchanged. Earlier results stay historical.
[Current host checks](settings-host/validation/2026-10-15-shortcut-retry/checks.md),
[overlay baseline](overlay-session/validation/2026-10-15-shortcut-retry/README.md),
[rain integration](drop-motion/validation/2026-10-15-shortcut-retry/README.md). Draft acceptance is unchanged.

## Native localization/layout parity — 2026-10-16

Source `c7da63dbc30ced3712ea9e5d357be6737791128a` corrects hook button AX containment
and narrow English status truncation. Screener now captures all seven sections at both
widths with language metadata. Host native_controls/operation_semantics/one_settings_owner/
default_off/material_composition retain their requirements; unchanged HC roles and source
paths need no cosmetic map edits. Only settings-host identities are refreshed.
[Current validation](settings-host/validation/2026-10-16-parity/README.md) separates 44
hierarchy frames, actual wide EN/RU app observations, local lint/localization and structure.
Tab/VoiceOver and actual-app narrow interaction remain open. Catalog documentation is
corrected without changing its runtime baseline. Other subsystem evidence stays historical;
formal acceptance stays draft, new settings stay opt-in, and toolbar blur is deferred.

## Shared slider columns — 2026-10-18

Source `07e7d5723ce03a34524443c40342354a6adce65e` replaces per-row LabeledContent
allocation with shared HStack column proportions and text-scaled readout width.
SettingsCatalog.NativeComponents and SettingsPage.NativePresentation.Forms remain the
responsible roles. Catalog host_owned_binding/native_controls/platform_availability
and parent host native_controls/one_settings_owner/default_off/material_composition
retain their meanings; catalog draft.5 folds the requested alignment into the existing
row contract. The catalog HCS composition string is corrected, preserving stable IDs.
Host/catalog current source/map hashes are refreshed; other subsystem evidence remains
historical. [Fresh checks](settings-host/validation/2026-10-18-alignment/README.md)
separate 44 Screener layout frames, app/catalog product builds, lint and structure from
physical input/compositor acceptance. Native settings stay opt-in; toolbar blur is deferred.

## PR #31 P2 adaptive slider correction — 2026-10-18

Runtime `d4b2d40745d31e1d862bb374c2b8e876efe7c13d` prevents readout space from collapsing
tracks: ViewThatFits stacks label/readout as needed and every Slider retains a 120-point
minimum. Catalog host_owned_binding/native_controls/platform_availability and parent host
native_controls/one_settings_owner/default_off/material_composition remain applicable.
Draft.6 folds the adaptive exception into the existing row contract; stable HC roles and
claim IDs remain, with composition text and current host/catalog identities refreshed.
[Fresh validation](settings-host/validation/2026-10-18-alignment-review/README.md) records
48 named Screener frames including explicit large-font narrow states, catalog build,
lint and structure. The failed in-process AX probe is not red/green regression evidence.
Prior live-app passes remain historical; physical accessibility and CI acceptance are separate.

## Rain composition pilot — 2026-10-18

Runtime `a250900ae2db17ce8d6086210860754feb1ff036` and exact window-frame fixture
update `e86996b8da2e91c3b16083286e60bbd7cf984ab6` preserve SettingsPage.NativePresentation
roles while revising host material_composition in draft.6. Rain has a scrollable
localized heading, three native groups, a rectangular system foundation and an
outlined open preview; other sections retain their shared rounded panels. System
appearance, shared bindings, 100% viewport, one renderer and default-off routing remain.
Catalog source and stable host_owned_binding/native_controls/platform_availability
claims are unchanged; its prior runtime baseline remains current, not reaccepted.
[New source/map identity and validation](settings-host/validation/2026-10-18-rain-composition/README.md)
separate 54 hierarchy frames, actual wide EN-light/dark and RU-light/dark and restored accessibility
settings, unit/Metal lifecycle checks and structure from owner acceptance. SCK capture
did not complete; narrow compositor, macOS 15 physical runtime
and keyboard/VoiceOver remain unproven. Prior validation stays historical.

## Preview width allocation — 2026-10-18

Runtime `cab0e76da217f889450df8f372e08e094e973e03` caps wide native forms at 480pt and gives additional width to the
open preview (minimum240pt). Narrow vertical layout and the single 100% renderer
remain unchanged. Host independent_preview is clarified in draft.7; no library,
renderer, preferences or other domain algorithms change. Stable HC roles and
claim IDs remain. [Fresh baseline](settings-host/validation/2026-10-18-preview-growth/README.md)
separates 58 hierarchy frames and actual native Zoom before/after observations
from structural/hash checks and owner acceptance. Previous evidence stays historical.

## Rounded Rain panel — 2026-10-18

Runtime `25e7aaa0bd9e32418294c4fa54720e06fcc39ac4` reuses SettingsMaterialPanel instead of Rain's rectangular
background branch. Material and clipping both use existing16pt rounded corners;
preview growth and 480pt form cap remain. Draft.8 updates material_composition and
the existing HC Forms composition. Catalog/library and renderer sources are unchanged.
[Fresh baseline](settings-host/validation/2026-10-18-panel-corners/README.md) separates build, visual
observation, lint and structure from prior historical58frame/Zoom evidence and acceptance.

## Native slider appearance and SDK correction — 2026-10-18

Runtime `6c464040ddac981596bebb931450f5ab48e1840d` hides dense slider ticks while retaining step-grid writes and
one-step accessibility adjustments. Catalog draft.7 and host draft.9 refresh shared
control/provider and active-SDK packaging obligations. HC identities remain stable;
provider NativeComponents/Packaging and parent NativePresentation properties reflect
the new source, with separate source/map hashes. App/catalog/release/native-trace
helpers use active SDK metadata and preserve manifest deployment minimum (15.0).
Fresh app/catalog products verifySDK27;16settings tests pass.
[Current evidence](settings-host/validation/2026-10-18-native-sliders/README.md) separates real step/drag
observations and SDK15→27 A/B from structure and acceptance. SDK27 produces native
Liquid Glass **and actual toolbar overpaint**. Earlier fixture-only classification
was too broad; compatibility SDK15 actual observations remain valid only for that
profile. The owner deferred the band; Navigation/Forms safe-area interaction is open,
visual acceptance and default-on/release readiness are not established. Full keyboard/
VoiceOver, narrow compositor and physical macOS15 runtime remain unproven.

## 2026-10-18 — Active rain tint

Host draft.10 material_composition uses the existing active rain color for root tint
and native sidebar listItemTint. NativePresentation/Navigation/SettingsBinding roles
remain stable; shared provider and renderer unchanged. [Baseline](settings-host/validation/2026-10-18-rain-tint/README.md)
records current source and separates UI observations from structural validity.
Known SDK27 toolbar band remains deferred; no default-on or release acceptance.

## 2026-10-19 — Native Liquid Glass panels

Catalog draft.8 material_panel/platform_availability and host draft.11
material_composition describe regular Liquid Glass on macOS26+, preserving macOS15
and opaque accessibility fallbacks. Shared provider source and both consumers
repinned at bc7294f; stable roles/claim IDs retained.
[Current evidence](settings-host/validation/2026-10-19-liquid-glass/README.md) separates native UI
observations, source-reviewed fallbacks and structural checks. Toolbar blur is
known/deferred; visual acceptance and rollout remain owner decisions.

## 2026-10-19 — Toolbar-free native settings

Host draft.12 native_controls describes system toolbar hiding, retained standard
window controls, in-panel headings and native sidebar recovery/dragging. Stable
Navigation/NativePresentation/Forms roles retained; library provider unchanged.
[Current baseline](settings-host/validation/2026-10-19-no-toolbar/README.md) separates source,
actual window observations and structure. Historical toolbar-band evidence remains
valid for its old source; no default-on rollout or full accessibility acceptance.

## 2026-10-19 — Sidebar identity header

Host draft.13 native_controls folds the64pt app icon, Dreams title and Agentic
Screensaver subtitle into Navigation presentation. Existing roles/claim IDs and
provider remain stable. [Current evidence](settings-host/validation/2026-10-19-sidebar-brand/README.md)
pins source and separately records local/visual checks; old16-test passes remain
historical and do not assert new screenshot or accessibility acceptance.

## 2026-10-19 — Fixed sidebar product requirement

Owner replaced hide/show with an always-visible sidebar. Host draft.14
native_controls and Navigation properties updated; stable role/claim IDs retained.
Branding, native selection and shared provider unchanged.
[Current baseline](settings-host/validation/2026-10-19-fixed-sidebar/README.md) distinguishes new
UI evidence from historical hide/show passes; narrow/drag/full a11y remain open.

## 2026-10-19 — Sidebar top inset

Removed redundant44pt brand padding; system safe area remains. draft.14
native_controls/material_composition and unchanged Navigation/Forms maps still
apply; implementation binding/source identity refreshed without cosmetic claims.
[Current evidence](settings-host/validation/2026-10-19-sidebar-inset/README.md) preserves old
spacing observations and separates current build/structure from visual acceptance.

## 2026-10-19 — Native sidebar row refinement

Host draft.15 material_composition describes primary inactive icons and active
rain tint on the selected icon. Rain-only12pt padding removed to prevent preview
header/footer displacement; the outline remains layout-neutral. Native List/Label rows receive uniform icon slots,
body text and more generous native insets/minimum height. Stable roles/claim IDs
retained; provider/renderer unchanged. [Baseline](settings-host/validation/2026-10-19-sidebar-rows/README.md)
separates current source, native UI observation and structural validity.

## 2026-10-19 — Full-width preview help

The compact preview help panel now accepts all offered width with leading text
alignment. Existing LivePreview/material_composition and preview_scale obligations
remain valid; no map/contract semantics or provider change. [New source baseline](settings-host/validation/2026-10-19-preview-help-width/README.md)
repins implementation and preserves prior visual evidence on its historical source.

## 2026-10-19 — Prominent preview playback

Host draft.16 folds heading removal and large fixed-content prominent glass playback
into material_composition/LivePreview. Root rain tint and native accessibility labels
remain; one renderer, full-width help and playback lifetime unchanged.
[Current baseline](settings-host/validation/2026-10-19-playback-button/README.md) separates source, structure and actual UI.

## 2026-10-19 — Unframed preview

Host draft.17 removes the enclosing outline from material_composition/LivePreview;
native glass button/help edges remain. Stable renderer/playback and parent obligations
retained. [Current evidence](settings-host/validation/2026-10-19-no-preview-outline/README.md) preserves earlier baselines.

## 2026-10-19 — Native setting icons

Host draft.18 and catalog draft.9 bind shared SettingsRowLabel and optional
SettingsSliderRow symbol presentation. Stable Forms/NativeComponents roles and
claim identities remain; icon slots are decorative and state/control semantics
unchanged. Both consumers repinned to [current source and validation](settings-host/validation/2026-10-19-content-icons/README.md).
Full VoiceOver/macOS15 acceptance remains separate.
