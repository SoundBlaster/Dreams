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

## Observations

The isolated QA app (PID 86330, runtime 73417b9 identical to main before this fix)
exposes sliders as AXSlider, with accessible titles, numeric AXValue, formatted
AXValueDescription, and AXIncrement/AXDecrement. Speed changed 0.43→0.44→0.43;
the readout changed with it and the initial setting was restored.

A standalone executable compiled the actual provider source alongside bare native
SwiftUI Sliders. Before the fix the no-help row had an empty AXRoleDescription,
while a native no-help Slider had “slider”. After the fix both have “slider”; all
six controls retain AXSlider and Increment/Decrement. Help/hint text appears in
AXRoleDescription rather than AXHelp for bare SwiftUI Slider too on this host.
This observed SDK behavior is not an application-specific role loss. General
buttons/pickers expose AXHelp normally.

Raw captures: [General](general-raw-ax.json), [Rain](rain-raw-ax.json),
[comparison before](comparison-before.json), [comparison after](comparison-after.json),
[action roundtrip](actions.log). Reproduction sources: [reader](read-ax.swift),
[action probe](actions.swift), [fixture](fixture.swift). Fixture compiled with
SwiftUI from the installed Xcode SDK 27, deployment target macOS 15, outputs on TB5.

The fixture after snapshot uses runtime b839251 provider. Its constant readout is
not evidence of readout synchronization; the action roundtrip uses the actual QA app.

Release build passed ([log](build.log)). Structural checks and lint are recorded
separately; neither proves assistive-technology acceptance. Actual VoiceOver speech,
hover tooltip popup, RU and macOS15 runtime remain unverified unless a later
operator report explicitly establishes them. No production settings or hooks changed.

## Assistive-technology limits and cleanup

[Operator report](report.md) records the bounded VoiceOver attempts. VoiceOver
started OFF, was temporarily enabled through System Settings, and was restored OFF
([final switch state](final-attempt-restored-off-ax.txt),
[cleanup screenshot](voiceover-restored-off.png)). Caption panel was already enabled
([initial setting](caption-initial-ax.txt)) and was not changed. CUA could not access
a VoiceOver process/caption output (NSOSStatus -600), so spoken announcements and
VoiceOver focus traversal remain unverified. The raw action test above is a separate
system AX check, not a claim of VoiceOver operation. Hover popup remains unverified.
The parent-owned fixture was terminated after the comparison.

[Lint](lint.log) and [Hypercode/SpecPM structure](structure.log) passed. Lint retains
the existing unused_import configuration warning. Source/map/snapshot hash audit
passed all 60 host entries and 25 catalog entries. Tools: specpm 0.2.0 and Hypercode
SHA256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
