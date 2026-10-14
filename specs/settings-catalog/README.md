# Native settings catalog — draft

Standalone first-stage consumer boundary: `dreams.settings.catalog`.
The [package](../../Packages/DreamsSettingsUI/README.md) documents launch and library usage.
[Contract](specs/catalog.spec.yaml), [map](../hypercode/settings-catalog.hc) and
[properties](../hypercode/settings-catalog.hcs) describe the separate showcase app.
[Source identity](evidence/2026-10-14/source-identity.json) and
[validation](validation/2026-10-14/README.md) identify current evidence.

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
