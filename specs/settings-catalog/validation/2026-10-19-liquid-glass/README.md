# Native Liquid Glass panels — 2026-10-19

Runtime `bc7294f88b6f3c1fda0596c6a59a198395d44882`. [Source/map identity](../../evidence/2026-10-19-liquid-glass/source-identity.json).

SettingsMaterialPanel uses native regular glassEffect on macOS26+ in the existing
16-point rounded shape. macOS15 retains regularMaterial. Reduce Transparency and
increased contrast select an opaque semantic background before the OS branch.
Only the background branches: caller content keeps its structural identity when
accessibility preferences change. No whole-panel interactive glass, custom control
input, opacity slider, renderer, preference or timer is added. Grouped Form row
fills remain native; the pane floats as the functional settings layer over rain.
The catalog's bilingual specimen captions now describe the adaptive surface.

Affected claims: catalog material_panel/platform_availability and host
material_composition/native_controls. NativeComponents/Forms roles and capability
IDs remain stable; host dependency border is repinned to the shared component.
Other claims retain their obligations. Descriptive drafts remain unaccepted.

Builds: app release and catalog product (warnings-as-errors) use SDK27 linked
metadata and macOS15 minimum with separate verified TB5 scratch directories.
See test/lint/structure logs and actual QA below. Source review verifies fallback
branches; no physical macOS15 or accessibility-setting transition is claimed.
Known toolbar blur band remains deferred. No release or default-on rollout.

## Local verification

- [App build](app-build.log): release success, linked SDK27/minos15 guard passed.
- [Catalog build](catalog-build.log): warnings-as-errors success, SDK guard passed.
- [Settings tests](settings-tests.log): 16 tests passed; conditional preview/trace
  cases skipped as logged. Tests do not establish glass pixels.
- [Lint](lint.log): passed, known SwiftLint unused_import configuration warning.
- [HC/SpecPM](structure.log): passed; existing unresolved external-capability
  warnings remain descriptive-draft dependencies. All live/snapshot hashes checked.

Tools: Swift6.4 / Testing2084, SpecPM0.2.0, Hypercode binary SHA256
6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f.

## Actual UI observations

[Dark](dark.png) and [light](light.png), [report](ui-report.md): regular glass
shows blurred blue columns/bright heads and refractive panel edges at100%density.
Labels/readouts and native row fills remain readable in these captures; muted
helper text is lower contrast. Controls and sidebar retain active rain tint.
Light was forced through an isolated diagnostic Aqua plist override, so this is
not proof of unmodified follow-system transitions. Production preferences and
system theme were unchanged. The existing toolbar band still hides top headings.
No full accessibility/compositor/performance acceptance is inferred.
