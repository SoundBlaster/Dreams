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
| DesktopApplication.SettingsPage | macOS user / legacy or native launch | dreams.settings.host | Current aa11113 [appearance recipes/palette](settings-host/validation/2026-10-21-appearance/README.md); grouped forms, shared owner and default-off routing | Owner visual acceptance; narrow compositor and keyboard/VoiceOver |
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
| TelevisionApplication / rain and clock | Apple TV user / clock on or hidden | dreams.tv.rain descriptive draft | [Current TV baseline](tvos/validation/2026-10-21-focus-input/README.md); shared simulation/pulse plus TV host | Owner reports Release slowdown resolved; physical swipe, measured performance and spoken VoiceOver remain unverified |

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

## 2026-10-19 — Native settings parity corrections

Host draft.19 updates native_controls/operation_semantics for reset error completion,
existing help, shared runtime/display text and Return default action. Stable
Forms/SettingsBinding roles and parent obligations retained; shared provider unchanged.
[Baseline](settings-host/validation/2026-10-19-parity-fixes/README.md) separates Carbon regression
verification, structural checks and actual UI; no default-on rollout implied.

Actual AX inspection found row-level help did not reach Slider. Catalog draft.10
adds optional direct native Slider help; host draft.19 consumer baseline refreshed.
Provider state/range/step ownership and role IDs retained.

## 2026-10-20 — native accessibility audit

Runtime `b839251fbe0835976af104000f2320a03367006f` fixes empty optional Slider help. Catalog draft.11 and host
draft.20 preserve stable roles/claims and unchanged maps. New source identities
replace the changed provider snapshot; historical observations remain preserved.
[Audit](settings-host/validation/2026-10-20-accessibility/README.md) distinguishes rawAX/action
results and bare SwiftUI comparison from unverified VoiceOver speech/hover behavior.
Other profiles remain outside this audit.

## 2026-10-20 — release 0.1.9 packaging

VERSION and both plugin manifest versions advance together to 0.1.9. No runtime
behavior, map roles or contract claims change; native settings still require an
explicit --native-settings launch argument. Existing source baselines remain
historical evidence, not a new test claim for the release commit.

[Release 0.1.9 baseline](release/validation/2026-10-20-0.1.9/README.md) records
metadata hashes, current host/catalog identity checks and signed/notarized artifact
preparation separately from historical runtime tests and later GitHub publication.

## 2026-10-21 — native macOS appearance recipes and palette

The user requested prototype presets and quick colors, starting with macOS.
Settings host draft.21 adds `quick_appearance`, folded into Forms and SettingsBinding.
NativeAppearancePreset defines Classic/Dimmed/Monochrome appearance values; native
recipe Toggles and palette Buttons use one existing controller, with derived
selection/Custom status. Native controls, one_settings_owner, operation_semantics,
material_composition and independent_preview retain their stable IDs and ownership.
Color/glow update only the active background profile; spread/pulse are shared.
No motion/grid/glyph or tvOS behavior changes. The selected color continues to
supply window tint. App-level assembly remains one settings owner and one preview.

[New appearance baseline](settings-host/validation/2026-10-21-appearance/README.md)
records new source/map identities and current checks. Earlier evidence stays on its
original runtime; structural validation, model tests, native trace pixels and
assistive input acceptance are separate. macOS 15 runtime remains unverified.

## 2026-10-21 — tvOS rain/settings parity

User confirmed TV adoption of desktop rain controls while preserving TV clock and
excluding agent integrations and desktop-window/session functions. New TV profile
covers grid, motion, simultaneous search, independent real-time pulse, pale-head
visibility/cycling, RGB/spread/glow, dynamic restored/classic glyph resources,
normalized saved settings, native remote input, one live preview and reset.
Existing TV density/exposure/clock defaults and mirror variants remain intentional
compatibility choices; this is feature parity rather than pixel equality.

[TV draft](tvos/README.md) recovers Lifecycle/Settings/Tuning and renderer children
as one bounded capability; [matrix](../tvOS/parity.md) lists platform distinctions.
Parent TelevisionApplication keeps its identity and points at the new detail.
Desktop motion/search/head/pulse contracts keep their macOS scope and existing
claim IDs. A provenance note now distinguishes later TV adoption rather than
claiming TV still has no pulse option. No desktop implementation or agent paths
change, and macOS test passes are not claimed as TV evidence.

The [dated TV baseline](tvos/validation/2026-10-21-parity/README.md) pins source/map
snapshots, command results and simulator observations. Earlier TV observations stay
historical. New contracts remain descriptive drafts pending acceptance.

## 2026-10-21 — centered TV settings panel and Play/Pause menu exit

User requested centered settings with inner spacing and rounded corners, and
Play/Pause to hide the menu. TV draft.2 updates remote_settings; Play/Pause opens
settings from rain and closes the open menu, while Live preview retains its own
pause toggle. Settings now uses 24-point inner padding and a 28-point rounded
material surface, capped at 1100 points and centered in the available area.
Lifecycle, tuning, renderer and desktop/agent boundaries are unchanged.

[New TV validation](tvos/validation/2026-10-21-centered-menu/README.md) supersedes
only the changed UI source/map identities; older tests and screenshots remain
historical and are not presented as new passes. Stable TV role/claim IDs remain.

## 2026-10-21 — TV settings focus overflow repair

User's enlarged screenshot exposed flat side cuts on focused native rows. The
inner List mask clipped tvOS focus expansion. Remove that mask and disable scroll viewport clipping; keep the
24-point inner padding and rounded 28-point panel. Stable `remote_settings`,
`lifecycle` and `platform_boundary` claims and HC roles still apply; no semantic
contract or map rewrite is needed. The parent still owns one renderer and routes
remote input to settings. Earlier statements that focus edges were clipping-free
are superseded; their captures and results remain historical.

[Current focus validation](tvos/validation/2026-10-21-focus-overflow/README.md) pins the changed
Settings source and rechecks unchanged source/map/font identities. Contracts remain
descriptive drafts; physical TV and spoken VoiceOver are still unverified.

## 2026-10-21 — TV native horizontal input and Release feedback

TV draft.3 retains `remote_settings` and existing roles/assembly obligations while
explicitly covering touch-surface swipe adjustment through native failed focus
movement headings. Vertical List focus and reset confirmation remain guarded.
[Current baseline](tvos/validation/2026-10-21-focus-input/README.md) separates simulator
commands, physical owner feedback on Release and pending physical remote swipe acceptance.
The renderer was not changed; Release removed the owner's observed severe slowdown,
without a valid Instruments trace or quantified performance acceptance.

## 2026-10-22 — measurement-first performance probe

New DesktopApplication.PerformanceProbe role covers a bounded macOS windowed
production renderer for contributors. Its Scenario/RunLifetime/Measurement/
ReportExport responsibilities map to the draft dreams.performance.measure claims
isolation, observation, lifetime and provenance. [Probe contract and evidence](performance/README.md).

Existing rain motion/search/head/pulse and preview_scale/lifecycle requirements
remain unchanged: ordinary launches have no recorder and retain existing paths.
CaptureVisibility and TV code are unchanged. Scripted agent traffic, native preview
reopen/capture latency, full-screen/multi-display and physical TV measurement are
explicit backlog. Existing historical passes are not evidence for this source.

Current source binding refreshes for drop_motion/search_occupancy/head_visibility/
glyph_pulse and settings host preview_scale/playback_lifetime retain stable IDs.
The normal nil-recorder path preserves their requirements; changed renderer inputs
and the optional recorder dependency have fresh snapshots. Overlay capture and
TV bindings are unchanged because no owned source in those boundaries changed.

Fifteen valid Release windowed runs (five each of normal, dense and dense-no-glow)
are pinned to runtime `6cc029c`. The later `32ebeb5` probe guards have separate
build/test/smoke evidence; the hardware baseline is not relabeled for that source.
Uncalibrated instrumentation overhead and interactive-host variance prevent a
small-gain acceptance threshold. No optimization issue is closed by these data.

## 2026-10-22 — collector calibration

DesktopApplication.PerformanceProbe.Calibration extends the existing contributor
boundary with control/full profiles and a common outer observer. Stable claims
isolation/observation/lifetime/provenance remain; additive calibration covers
matching identities, signed bracketing differences and explicit unresolved cost.
[Current draft and evidence](performance/README.md) do not accept a performance budget.

Runtime checkpoint `bb400f4` changes only diagnostic launch, calibration model,
runners/analysis and tests. MatrixRain/RainRenderer/MatrixSimulation, user settings,
macOS overlay/display lifecycle, integrations, glyph data and tvOS are unchanged.
Existing drop_motion/search_occupancy/head_visibility/glyph_pulse and settings host
preview_scale/playback_lifetime claims still apply; their pinned implementation
files are byte-identical, so their current bindings and historical evidence stay
intact. No coverage or acceptance is inferred for the excluded profiles.

Fifteen valid calibration runs completed at runtime `bb400f4`, with five C/F/C
blocks and nominal thermal states. Paired process CPU differences ranged from
-0.085 to +0.401 ms/draw; absolute control spread reached 0.517 ms/draw. Cost is
unresolved, not zero. Common-observer cost remains excluded and no historical
percentile is corrected. Analysis-only checkpoint `7479e60` tightens hardware
identity/status validation without changing any measured statistic or app source.

## 2026-10-23 — fixed synthetic feed baseline

PerformanceProbe.SyntheticFeed folds Publication/SnapshotObservation/DeliveryProxy
into dreams.performance.measure, with additive feed_observation and the existing
isolation/observation/lifetime/provenance claims. Its parent correlates external
publication identity and the shared host clock with successful snapshot receipt
and actual drawable presentation. A stable event-letter instance is a proxy,
not pixels or whole-label acceptance. [Protocol](../research/performance/feed-protocol.md)
and [current evidence](performance/validation/2026-10-23-feed/README.md) preserve these limits.

Runtime `29e07ea` retains synchronous production polling and the rendering algorithm;
observations are enabled only by --performance-feed. Pulse packets retain an event
ID and encoding reports success for diagnostic correlation. Motion/search/head/
pulse formulas and preview viewport/playback/lifetime paths are unchanged. Current
bindings for dreams.rain.drop_motion/search_occupancy/head_visibility/glyph_pulse
and dreams.settings.host are refreshed for the affected renderer dependency.
The identity audit also found pre-existing settings-source snapshot drift and
refreshes those source identities; historical UI observations are not promoted
to current runtime evidence. Claims remain drafts; no new visual acceptance follows.

Production KeywordFeed is a border snapshot for this diagnostic consumer, not a
recovered hook/MCP integration contract. Its I/O remains on the draw path and
the desired no-frame-I/O criterion of #42 is still outstanding. Overlay/capture
and tvOS source/claims are unchanged. This macOS window baseline does not cover
multi-renderer sharing, lock contention, cold storage or pixel/full-label latency.

## 2026-10-23 — shared background mailbox reader

Renderer.FeedInput now composes the newly recovered descriptive draft
[dreams.feed.read](keyword-feed/README.md). SnapshotCache, SubscriptionLifetime,
BackgroundObservation (DirectoryChanges/FallbackRefresh) and OfflineRefresh cover
the macOS render consumer. Read/prune/lock work is moved to a concurrent utility
task; ordinary draw reads MainActor-owned memory. Production renderers share the
default reader, while per-renderer consumed IDs preserve delivery to every surface.
Status RPC and legacy session listing remain on-demand synchronous consumers;
producer hook/MCP semantics remain uncovered by this reader draft.

Runtime `680833b` owns this change and the fixed alternating comparison protocol.
The performance draft adds feed_comparison and independent background read samples;
feedRefresh in an after-frame identifies consumed input, not I/O by that draw.
Frame, process, source, runner and fixture identities remain distinct. Existing
motion/search/head/pulse and preview_scale/preview_lifetime/preview_playback claims
keep their IDs and requirements; renderer bindings are refreshed. Simulation,
colour formulas and viewport code are unchanged. Preview still releases its
renderer, which releases its reader lease. Overlay controller/display/capture
source and requirements are unchanged; the Renderer map adds its ready-input
assembly dependency without claiming physical overlay acceptance.

Functional evidence covers cache retention during lock contention, expiry without
a publisher write, directory replacement, last-consumer release/restart and two
offscreen renderers displaying the same event. A parallel Metal fixture initially
shared a mailbox with the crop test; its input was isolated, retaining exact pixel
assertions. Historical passes are not relabeled. [Dated evidence](performance/validation/2026-10-23-shared-reader/README.md)
separates tests, structural checks, paired window measurements and owner acceptance.
Physical TV/multi-display performance, pixel/full-label event latency, cold storage
and total CPU/energy remain unmeasured.

Current incremental coverage (2026-10-23):

| Role | Draft capability | Evidence / remaining work |
| --- | --- | --- |
| Renderer.FeedInput / KeywordFeedReader | dreams.feed.read | Source, lifecycle and two-renderer tests; paired latency benefit; rare cadence gaps unresolved |
| PerformanceProbe.SyntheticFeed.BackgroundReads | dreams.performance.measure / feed_comparison | Five complete pairs plus separate two-pair diagnostic; no automatic performance acceptance |

All 120 primary events arrived and all 420 after-reads were off main. Each pair's
delivery p95 improved (778–1078 ms before, 139–177 ms after). Three after-only
>50 ms presentation intervals occurred in the primary series and two more in
the separate quiet diagnostic, versus none before. p99 stayed about 41.667 ms;
this does not establish absence of regression. Cadence acceptance and issue #42
remain open. All 15 raw reports and both variant identities are preserved.

## 2026-10-23 — cadence investigation (no runtime change)

[Diagnostic packet](performance/validation/2026-10-23-cadence-study/README.md)
keeps three profiling attempts separate from the original five-pair experiment.
FrameCPU/GPUCompletion/Presentation and BackgroundReads retain their source and
`dreams.performance.measure` observation/provenance/feed_comparison requirements.
Reader and parent assembly claims are unchanged; no runtime, map or binding changed.

The final native trace uniquely joins 905 command buffers to application draws.
For three covered long intervals, native commit-to-GPU wait is 0.48–0.62 ms, GPU
execution 5.85–6.72 ms, and the remaining GPU-end-to-recorded-presentation wait
35.99–58.94 ms. This locates those instrumented waits after GPU completion; it
does not assign their cause or explain the five historical unprofiled gaps.
The other three new gaps lie outside actual exported native coverage. One earlier
trace failed finalization; another did not cover its save-phase gaps. All reports
and failures are retained, without mixing profiler-confounded runs into baseline.
Cadence acceptance remains open, PR #54 remains draft and #42 stays open. Next
experiment: the same lightweight absolute GPU/commit observations on both variants,
with observer overhead checked and alternating unprofiled runs.

## 2026-10-23 — opt-in absolute timeline experiment

The [fixed protocol](../research/performance/timestamp-protocol.md) adds optional
commit API brackets and absolute GPU start/end to the existing diagnostic boundary.
`dreams.performance.measure` keeps existing claims and adds absolute_timeline and
timeline_calibration. FrameCPU/GPUCompletion/Presentation and Calibration fold this
into existing roles. On/off comparisons share the full feed collector and process
CPU observer; common integration cost is explicitly excluded.

Runtime `58d2097` is a new diagnostic derivative of the shared reader. Counterfactual
`f8b2a50` backports the same observer to synchronous-reader base `29e07ea`; its full
patch/source is retained as experimental input, not a newly accepted production
profile. Historical binaries and prior gaps cannot be relabeled with new clocks.
Motion/search/head/pulse and preview_scale/preview_lifetime/preview_playback retain
requirements; affected dependency source identities are refreshed. Reader, overlay,
display, capture and TV algorithms are unchanged. Collection is now complete;
acceptance remains open. No cadence remedy or numerical budget is accepted by
this instrumentation change.

All 30 preregistered runs are preserved in the
[absolute-timeline packet](performance/validation/2026-10-23-absolute-timeline/README.md).
All 360 events arrived; all input/clock/order/nominal-thermal checks pass. The ten
timed runs have no >50 ms interval; one after control with timestamps disabled
has a 74.999 ms interval and cannot supply absolute-stage attribution. Five timed
pairs retain lower observed delivery p95 after (132–219 ms vs 746–1129 ms).
Signed observer CPU deltas remain unresolved above time/control variation.

Other-process load was not captured. The owner subsequently reported another
parallel agent likely compiling Rust/Swift. This is an unmeasured confound, not a
proven explanation or a reason to erase a slow run. Report integrity does not
establish host-load isolation: these are interactive-host observations, not a clean
baseline or accepted CPU improvement. Historical gaps remain unresolved; #42 stays
open and #54 stays draft. The proposed next experiment requires a coordinated quiet
window and precommitted external-load observation/contamination rules.

Final analyzer `d86b7d2` adds order/nonoverlap guards without changing runtime or
statistics. Performance bindings are refreshed to that source; other affected
consumer bindings remain on byte-identical runtime `58d2097`. Current source/map,
before-fixture patch and archive integrity audits preserve these separate identities.
Existing parent and motion/settings/feed claims retain requirements and draft status;
structural checks, tests, measured observations and owner acceptance remain separate.

## 2026-10-24 — quiet-host prerequisites (no renderer comparison)

The [dated prerequisite packet](performance/validation/2026-10-24-quiet-host-preflight/README.md)
preserves the owner-offered window, observer CPU C/F/C check and both one-minute
idle references. No active compiler was detected, memory pressure and swap-out
counter were stable, but p95 busy CPU was 2.05/2.25 cores out of 12 against a fixed
1.5-core prerequisite. This conservative guard is not a hardware performance budget
or proof that the background caused any historical frame gap. Neither reference
was erased or relabeled; no renderer, build, install or settings migration followed.

PerformanceProbe.Calibration/ReportExport and dreams.performance.measure provenance,
observation, calibration, feed_comparison and timeline_calibration retain requirements.
Runtime/source bindings and maps are unchanged. The experimental helper is a pinned
input to this dated observation, not a supported host-monitor contract; reusable
environmental gates and comparable idle-condition definition remain explicit backlog.
Observer process CPU (about 0.055 CPU s/s incremental in one short block) is distinct
from renderer latency/total overhead. Cadence causality, observer cost acceptance,
#42 and #54/#55 readiness remain unresolved; physical tvOS evidence is unchanged.

## 2026-10-24 — native settings default rollout

The owner explicitly requested native settings by default, superseding the earlier
opt-in rollout requirement. Runtime `210e6f1` changes only NativeSettingsFeature:
ordinary launch selects native, --native-settings remains a compatible alias and
--legacy-settings wins in either argument order. Legacy-only regression fixtures
explicitly select their retained route at `b541faf`; shared controller, preferences,
renderer and overlay algorithms are unchanged. The installed app opens the native
window without either flag; existing application preference values were preserved.

Host draft.21 and SettingsHost.FeatureFlag retain role/claim identities. The historical
default_off claim ID is deliberately versioned with the new owner-authorized routing
requirement, preserving earlier evidence rather than relabeling it. Native controls,
one_settings_owner, explicit_legacy_access, lifetime and parent overlay-exit obligations
remain in force. [Dated source/test/install evidence](settings-host/validation/2026-10-24-native-default/README.md)
separates default routing from full accessibility, compositor and performance acceptance.

Source identities also refresh legacy test fixtures for dreams.rain.drop_motion,
search_occupancy and glyph_pulse without changing their requirements or maps.
The audit found pre-existing snapshot drift in the build helper and several shared
settings dependencies; current bytes are now pinned, with no historical test pass
promoted to this source. Physical tvOS, capture/display routing and agent integrations
remain outside this change. Local installation is ad-hoc signed, not a release.


## 2026-10-24 — release 0.1.10 metadata

VERSION and both plugin manifests advance together to 0.1.10 after merged native
settings default rollout #56. No further runtime, map or contract behavior changes.
Current host/catalog/motion bindings are audited byte-for-byte; pre-existing catalog
build-helper snapshot drift is refreshed. Historical runtime/UI tests retain their
original source and profile. Packaging remains an unrecovered boundary.

[Metadata preparation](release/validation/2026-10-24-0.1.10/README.md) separates local
source/structural checks from signed/notarized artifact and publication verification
attached to the GitHub release. Default route, legacy access and shared owner
requirements remain in force; performance and physical TV acceptance are unchanged.

## 2026-10-24 — pr39 main integration

[Integration identities and scope](integration/2026-10-24/pr39/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## 2026-10-24 — pr40 main integration

[Integration identities and scope](integration/2026-10-24/pr40/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## 2026-10-24 — pr52 main integration

[Integration identities and scope](integration/2026-10-24/pr52/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## 2026-10-24 — pr53 main integration

[Integration identities and scope](integration/2026-10-24/pr53/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## 2026-10-24 — pr54 main integration

[Integration identities and scope](integration/2026-10-24/pr54/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## 2026-10-24 — pr55 main integration

[Integration identities and scope](integration/2026-10-24/pr55/README.md) preserve both incoming history and current main requirements. Dependency snapshot refreshes do not adopt older test passes as new evidence; performance acceptance and physical-device unknowns remain explicit.

## Interactive macOS menu — 2026-10-24

Recover `DesktopApplication.ApplicationMenu` / `dreams.desktop.main_menu`:
standard native application/edit/window commands are installed on regular
interactive launch. The status-item menu and accessory entry paths remain
separate. `dreams.settings.host` existing one-owner/reopen claims still apply:
Command-comma invokes the same retained SettingsPageController. Overlay session
and exit action semantics remain unchanged; only the app's main menu is added.
`build-app.sh` accepts an optional glyph-output path so the required app build can
keep generated glyph artifacts on the verified TB5 volume; its default and bundled
font bytes are unchanged. [Validation](application-menu/validation/2026-10-24/README.md).

## Saved macOS status-icon visibility — 2026-10-24

`DesktopApplication.ApplicationMenu.StatusItemVisibility` folds the minor native
icon-presence preference into `dreams.desktop.main_menu/status_item_visibility`;
`dreams.settings.host/menu_bar_icon` owns native General/legacy presentation.
Runtime/test source `f979c8c7d454589d225de75911c5fcdfe262c8b8`: one saved controller value, default/reset visible,
immediate visibility changes on the same NSStatusItem and unchanged shortcut/menu
ownership. Interactive main-menu Settings and Dock reopening remain available.
Accessory setup reads the saved value; publisher-only mode still has no item.

Updated maps and current full-file bindings preserve stable claim IDs and draft
acceptance. `dreams.overlay.session`, `dreams.overlay.exit`,
`dreams.rain.drop_motion`, `dreams.rain.search_occupancy`,
`dreams.rain.glyph_pulse` and `dreams.tv.rain` retain their algorithms and profile
obligations; their changed full-file bindings are refreshed with a dated impact
record, preserving previous evidence. TV execution/performance is not inferred
from this macOS run. [Current checks](application-menu/validation/2026-10-24-status-icon/README.md).

## Single desktop owner and preview reopening — 2026-10-24

`DesktopApplication.InstanceOwnership` / `dreams.desktop.single_instance` is a
new descriptive draft for startup mode admission, an atomic user-local process
lease, duplicate GUI handoff and exclusive full-control MCP/lab ownership.
Publisher-only and offline helpers remain distinct and cannot promote into a GUI.
Runtime/test source `a0cd20994743c20f941414be99b407d9b00cd11c`. The parent owns admission before menu/controller/
shortcut/window construction; native settings owns the retained window and
`dreams.settings.host/preview_reopen`, which replaces only a previously closed Metal canvas and clears its close
latch while preserving Play/Pause and retained window/navigation state. Main-menu native commands keep stable IDs;
owner-only accessory promotion is an explicit startup/lifecycle extension.

Current changed-file bindings and affected maps are refreshed. Overlay session
and exit claims retain their algorithms/obligations; old evidence remains
historical. tvOS, glyph tooling and renderer algorithms are unchanged.
[Checks and limits](application-menu/validation/2026-10-24-single-instance/README.md) distinguish
unit/source, concurrent process admission, MCP publishers and native UI motion.

## Optional FPS readout — 2026-10-24

`dreams.rain.fps` adds independent opt-in diagnostics to macOS and tvOS.
Affected parent claims: `dreams.settings.host` settings binding/preview lifecycle
and new `constraints.fps`; `dreams.tv.rain` lifecycle/platform boundary and new
`constraints.fps`. Existing motion/search/pulse and performance-probe claims keep
their semantics: this readout does not change their algorithms or acceptance.
[Contract](fps/README.md), [validation](fps/validation/2026-10-24/README.md).
TV GPU completion and macOS presentation are distinct; physical-device cadence
and overhead measurements remain outstanding. Historical evidence is preserved.

## TV paused preview and A8 default — 2026-10-24

Affected claims: `dreams.tv.rain` constraints.lifecycle/settings/platform_boundary,
new constraints.paused_preview and constraints.a8_glow_default; `dreams.rain.fps`
constraints.lifetime excludes manual paused frames. Stable roles and existing
motion/search/pulse contracts remain unchanged. [Dated evidence](tvos/validation/2026-10-24-paused-preview/README.md).
The owner's A8 observation isolates Glow as a substantial cost; it does not
establish GPU versus CPU attribution or a guaranteed frame rate. Measured
comparison and a cheaper glow implementation remain backlog.

## FPS inside rain cells — 2026-10-24

Owner clarification replaces pixel-positioned overlay geometry with reserved
rain cells on macOS and tvOS. `dreams.rain.fps` constraints.appearance and parent
renderer assembly change; cadence/opt-in/lifetime semantics remain unchanged.
[Current validation](fps/validation/2026-10-24-grid/README.md). Historical screenshots
of the separate overlay do not establish the new grid placement. Paused-preview
UI interaction could not be verified by the bounded simulator attempt; only a
running rain frame was observed, distinct from the passing TV unit tests and
physical install/launch.

## 2026-10-25 — pr62 combined-stack integration

[Integration scope and identities](integration/2026-10-25/pr62/README.md) preserve the FPS/TV and macOS menu/settings requirements together. Changed full-file bindings are refreshed without adopting historical passes for the new SHA.

## 2026-10-25 — pr63 combined-stack integration

[Integration scope and identities](integration/2026-10-25/pr63/README.md) preserve the FPS/TV and macOS menu/settings requirements together. Changed full-file bindings are refreshed without adopting historical passes for the new SHA.
