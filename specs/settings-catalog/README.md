# Native settings catalog — draft

Standalone first-stage consumer boundary: `dreams.settings.catalog`.
The [package](../../Packages/DreamsSettingsUI/README.md) documents launch and library usage.
[Contract](specs/catalog.spec.yaml), [map](../hypercode/settings-catalog.hc) and
[properties](../hypercode/settings-catalog.hcs) describe the separate showcase app.
[Current source identity](evidence/2026-10-18-alignment-review/source-identity.json) and
[validation](validation/2026-10-18-alignment-review/README.md) identify the shared slider column layout.
Original catalog validation remains historical.

| Consumer concern | Claim | Source responsibility | Evidence / limit |
| --- | --- | --- | --- |
| Actual Apple controls | native_controls | UI library and example views | Native APIs in source; no claim of complete HIG/VoiceOver conformity |
| Preserve current settings | independent_host / ephemeral_fixtures | Package graph and local State | Manifest/resource checks; production source unchanged |
| Native navigation | window_navigation | CatalogPage, native inspector | Source; interactive keyboard/window-size acceptance separate |
| Older macOS and accessibility | platform_availability | guarded GlassSpecimen, material environment | macOS 15 deployment compiles; physical macOS 15 run unobserved |
| Reusable row semantics | host_owned_binding | SettingsSliderRow | Host owns range/units, persistence and errors |
| Portable executable | localization_and_packaging | module resource ownership and app bundler | Artifact and signature checks |
| Future embedded preview | preview_limit | SettingsPreviewRegion | Placeholder only; renderer/glass integration deferred |

Parent assembly for the next stage must route through a feature flag defaulting
off, preserve the legacy settings frontend and inject the production settings owner
and renderer. Those are desired next-stage obligations, not implemented guarantees
of this catalog. Existing overlay/display/exit/motion/search/glyph claim IDs remain
applicable: their implementation and production package are unchanged in this work.

## Production adoption — 2026-10-14

The standalone catalog remains a separately built app with ephemeral fixtures.
Production now links only the UI composition library and provides a default-off
[settings host](../settings-host/README.md). This supersedes the historical
first-stage observation that the production manifest had no package dependency;
it does not give the catalog production state, lifecycle or renderer access.
[Current source and checks](validation/2026-10-14-native-host/README.md) are separate
from the preserved initial catalog evidence.

## Shared material panel — 2026-10-15

SettingsMaterialPanel is used by both the static material specimen and the opted-in
production host. It uses system regular material, with an opaque semantic background
for Reduce Transparency or increased contrast. It introduces no state owner, renderer
or preferences into the package. See [fresh checks](validation/2026-10-15-materials/README.md).

Shared slider column layout: [2026-10-18](validation/2026-10-18-alignment/README.md).

Adaptive slider P2 correction: [2026-10-18 review](validation/2026-10-18-alignment-review/README.md).

Dense tick cleanup and native SDK appearance: [2026-10-18 SDK/sliders](validation/2026-10-18-native-sliders/README.md).

Native Liquid Glass panels: [2026-10-19-liquid-glass](validation/2026-10-19-liquid-glass/README.md).

Content setting icons: [2026-10-19-content-icons](validation/2026-10-19-content-icons/README.md).
