# Dense slider policy and SDK packaging — 2026-10-18

Runtime `6c464040ddac981596bebb931450f5ab48e1840d` refreshes catalog draft.7 host_owned_binding/platform_availability.
[Identity](../../evidence/2026-10-18-native-sliders/source-identity.json) includes shared SettingsSliderRow,
SDK build helper and catalog packaging script. NativeComponents and Packaging HC roles
retain identity with new tick/SDK properties. Parent host border/obligations are revisited
in [the host baseline](../../../settings-host/validation/2026-10-18-native-sliders/README.md).

More than20 intervals use a native continuous Slider with range-clamped step-grid
binding and one-step accessibility adjustments. Sparse scales remain native stepped.
There is no public API or persistence change. Keyboard semantics stay native but parity
with the previous stepped control is not proven by accessibility increment tests.

The catalog product builds with warnings-as-errors and Mach-O minos15/sdk27. See
[build log](../../../settings-host/validation/2026-10-18-native-sliders/catalog-build.log),
[metadata](../../../settings-host/validation/2026-10-18-native-sliders/sdk-metadata.log),
[structure](../../../settings-host/validation/2026-10-18-native-sliders/structure.log),
[hash checks](identities.log). Actual shared-control observations are in the host app;
no new interactive catalog-window acceptance or packaged resource pass is claimed.
Prior fixture evidence stays historical. The host SDK27 toolbar overpaint remains a
known deferred visual defect, not a successful glass/layout acceptance result.
