# Test-hosted Metal trace — 2026-10-30

The consumer is a developer inspecting the native settings preview through
Screener MCP. This test-only capture workflow does not change production
settings, preview, overlay or renderer behavior. Stable draft claims
`dreams.settings.host/native_controls`, `independent_preview`,
`preview_playback`, and `preview_reopen` remain unchanged. Existing acceptance
and earlier evidence remain scoped to their original inputs.

## Inputs and tool identity

- Base revision: `935ea3b832083764c9e5ee655cc9b1784caeb6ef`; changes were
  uncommitted at test time. macOS 27.0 (26A428), Xcode 27.1 (27A9275), Swift 6.4,
  arm64, Screener 0.2.0 revision `085252854d22dcc344d494d38496b402a92b308f`.
- Changed inputs, SHA-256:
  - `Makefile`: `c1ee59e11d73a285c333b0c5efaa1465fcb6724f8d3d2e620001d7bdbd47ffea`
  - `Tests/DreamsTests/NativeSettingsTraceTests.swift`: `51223023520a295de119c662692a3019a84dacf91fed899d2fd023054847dd53`
  - `scripts/test-native-settings-trace.py`: `285f40340fc7b5376b6270666cb740d3ba683dbfba5d10cd24a0568917a60095`
- Existing map hashes: `settings-host.hc` `17c88eda8078395cff8db6dccff75ece562f0de2bef22c7cff7a3337d6417c0e`;
  `settings-host.hcs` `399b5443cfd0150de2b14d768bef3d7f3efd17184b3fc9047771272038917132`.
  `specs/host.spec.yaml`: `eab9dfff01b479afe191f6b36c8c35ca8e775d0ea551cec8a3f54a55d6c85d87`.
- Hypercode release executable SHA-256:
  `ed236f86551590d3b0539c66e572cdfcdcf0ce567fa3913e2f2dfa0097dfc78b`;
  SpecPM 0.2.0; SwiftLint 0.63.3.

## Results

- `make trace-metal`, with SwiftPM scratch/cache on TB5: exit 0; four native
  compositor frames and a completed session. Resume retained the same renderer
  and advanced its frame counter. Session `F6753C4A-A824-4D2A-9C44-32A54F65E083`
  was read through MCP sessions → timeline → frame; the playing frame showed
  rain and settings. The test host displays a folder icon rather than the app icon.
- `make test-native-settings-trace`, same TB5 routing: exit 0; 35 hierarchy
  frames, session `3DCA1DB9-376A-480E-91C4-C357C483E365`. With
  `DREAMS_NATIVE_CAPTURE_BACKEND=screen-capture-kit`, exit 0 and 35 compositor
  frames, session `81F43FAE-9DB9-4B23-BF73-3B86C241AA5C`. The earlier unmodified
  full ScreenCaptureKit run also passed, session `BF0D98C5-C842-484A-AF1E-46442E1D8EA1`.
- `swiftlint lint --strict --no-cache Tests/DreamsTests/NativeSettingsTraceTests.swift`:
  exit 0, zero violations; configuration emitted its existing `unused_import` warning.
- `ruff check scripts/test-native-settings-trace.py`: exit 0.
- `make specs-check HYPERCODE=<identified release executable>`: exit 0;
  full structural diagnostics in [specs.log.gz](specs.log.gz). SpecPM reports
  unresolved external capability warnings; settings-host has three. These are
  not application acceptance or successful cross-package resolution.
- `git diff --check`: exit 0. Build output and package cache were routed to TB5.

## Limits

The fixture drives model state programmatically and captures its own test window;
it is not an attached recorder for a separately running Dreams process. Existing
screen-capture permission and an unlocked GUI are prerequisites. Physical input,
other displays, continuous video, capture without authorization, tvOS, and app
release acceptance were not tested. The old Metal pilot remains historical and
is not used as evidence for this source.
