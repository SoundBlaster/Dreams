# Shared material panel — 2026-10-15

Runtime `3910ebf93779f8da807bf361f89873092db03b7d`; [current identities](../../evidence/2026-10-15-materials/source-identity.json).
NativeMaterialsPage and the production host both consume SettingsMaterialPanel. Stable catalog
claim IDs remain. The platform_availability claim now includes opaque fallback for increased
contrast as well as Reduce Transparency. The new library interface is purely view composition;
no production renderer, state, preferences or timers enter the catalog.

[Host verification](../../../settings-host/validation/2026-10-15-materials/README.md) includes catalog
release build/packaging, lint and structural logs with command/tool identity. The 13 Screener frames
are production-host evidence, not standalone catalog UI acceptance. Accessibility fallbacks are
source-reviewed; physical macOS15/global accessibility toggle and standalone catalog visual
acceptance remain outstanding. Historical evidence remains historical and draft status is unchanged.
