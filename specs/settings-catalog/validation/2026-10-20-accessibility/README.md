# Native accessibility audit — 2026-10-20

Runtime `b839251fbe0835976af104000f2320a03367006f`. [Source/map identity](../../evidence/2026-10-20-accessibility/source-identity.json).

The shared SettingsSliderRow now omits `.help` entirely when its optional help is
nil, preserving the system role description. Caller-provided help remains attached
to the system Slider. Roles, names, formatted values, bindings, step precision,
keyboard behavior and native Increment/Decrement actions remain unchanged.

Affected claims: catalog host_owned_binding/native_controls; host native_controls
and one_settings_owner. Existing Forms/NativeComponents/SettingsBinding roles and
parent range/units, overlay lifetime and settings ownership obligations still apply.
Maps remain accurate and unchanged. These contracts remain descriptive drafts.

See the [host audit](../../../settings-host/validation/2026-10-20-accessibility/README.md) for raw system AX observations, fixture comparison and assistive-technology limits.
