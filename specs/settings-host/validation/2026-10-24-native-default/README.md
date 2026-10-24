# Native settings default — 2026-10-24

The owner requested native settings by default. Runtime
`210e6f19a36fb4ce94e4ce72438bdf070f64d526` changes only the launch-route predicate:
ordinary launch opens native settings, `--native-settings` remains compatible and
`--legacy-settings` selects legacy in either argument order. Advanced retains its
existing legacy-window action. No enablement preference or settings migration is added.

## Requirement and source impact

Host draft.21 intentionally supersedes the former opt-in rollout. Stable role
SettingsHost.FeatureFlag and historical claim identifier `default_off` are retained
for traceability; the claim's versioned requirement now describes native-default
routing. Earlier draft.20 and its tests remain historical. This is an explicit
owner-requested requirement change, not a weakened requirement inferred from code.

`native_controls`, `one_settings_owner`, `explicit_legacy_access`, `lifetime`,
preview claims and the parent overlay-exit obligations remain unchanged. The
controller, persistence keys, shared UI package implementation, renderer, overlays,
agent integration and TV code are unchanged. Native host behavior still does not
establish complete accessibility, compositor, performance or macOS 15 acceptance.

Test-only revision `b541faf` explicitly selects legacy for legacy control, pulse
and recorded-scenario regressions. The default native fixture opens through the
ordinary SettingsPageController initializer, then checks shared legacy fallback
and timer lifetime. [Source audit](source-audit.json) confirms no production source
changes between the built runtime and the final test revision, all 40 host and 24
shared motion/search/pulse binding snapshots match both current and pinned source.

[Host identity](../../evidence/2026-10-24-native-default/source-identity.json) and
[motion identity](../../../drop-motion/evidence/2026-10-24-native-default/source-identity.json)
preserve source/map hashes separately. The audit also refreshed pre-existing
snapshot drift in `swift-macos.sh` and shared settings dependencies; no historical
pass is relabeled as evidence for those current bytes. Motion/search/pulse
requirements and maps remain unchanged; only dependency/test identities refresh.

## Local build and tests

- Verified TB5 APFS UUID and separate worktree output root before building. `make app`
  uses the repository font/build/SDK/signing entry point; SwiftPM output/cache and
  Python bytecode are on TB5. The source font rebuild was deterministic; user glyph
  checkpoints were not accessed or modified.
- Runtime `210e6f1`: `make app` passed and the native settings selection reported
  19 tests / 1 suite passed. Final test revision `b541faf`: native plus explicit
  legacy regressions reported 22 tests / 3 suites passed. These overlap and are not
  additive. The opt-in Metal preview and Screener recording tests were skipped;
  no crop, full visual or VoiceOver acceptance follows from these runs.
- Commands, source identities and exit codes are preserved in
  [build/tests](build-tests.json) and [final regressions](regression.json). Both test
  invocations used a disposable feed separate from the owner's live feed. Full logs
  are losslessly retained with [digests](archive-integrity.json).
- Final lint/docs, HC/SpecPM and staged-diff checks are recorded in `checks.json`.
  Existing unresolved platform capabilities remain warnings, not accepted execution.

## Installed application verification

The built executable was staged and its ad-hoc code signature verified before
replacing `/Applications/Dreams.app`. The previous application and a preference
snapshot remain in the task's TB5 installation backup; the temporary Applications
rollback bundle was moved there after verification. [Installation identity](installation.json)
records both executable hashes and backup locations. This is a local 0.1.9 build,
not a new GitHub release or a notarization claim.

The app was gracefully restarted and opened **without either settings argument**.
Actual CUA accessibility inspection of `/Applications/Dreams.app` found window
`dreams.native-settings`, the Dreams / Agentic Screensaver header and all seven
sidebar sections. [UI verification](ui-verification.json) pins the installed
executable hash and observed process arguments. All 15 existing non-system
preference values checked before/after installation remained equal; preference
contents are kept local and are not published in this packet.

This proves the installed build's default native route and preserved saved values.
It does not replace full visual, physical TV, display/capture or performance tests.
The code change and review packet can be reviewed independently of the local install;
no CI monitoring, merge or release publication was performed.
