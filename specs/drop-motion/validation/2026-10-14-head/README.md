# Drop head regression — 2026-10-14

The new current identity is in [source-identity.json](../../evidence/2026-10-14-head/source-identity.json).
Older native-host/search/motion baselines remain historical. Unchanged motion/search claim IDs keep their meanings;
head appearance is recovered as a separate descriptive draft within the existing rain package.

The search rewrite at 58513ff removed standalone random mutation flashes. It did not directly change the old
head formula: that formula still multiplied low-ink heads by 0.2. Its fixed 0.11-second lifetime also predates
braking and can end before the next slower row arrival. A gap was skipped unconditionally by macOS rendering.
The correction makes only the current head pale independently of trail ink, carries it through its real flight
step and draws gaps transiently while they own the head. Search settlement remains unhighlighted.

[Aligned regression](regression.log) runs the final tests against unchanged main model/renderer bytes, then restores
the correction. [Corrected unit/GPU run](unit-metal.log) includes both background profiles, braking, dim ink, gap
heads, no glow, default global brightness, sequential expiry/search and transparent alpha fading.
The alpha-fade fixture explicitly disables search so shape mutation cannot change its sampled coverage.
[tvOS Simulator receipt](tvos-summary.json) contains 12 passing tests for the shared model and existing TV renderer;
TV still retains its own random-ink colour adaptation. No physical Apple TV or desktop compositor claim is made.

[Structural checks](structure.log), [lint](lint.log), [run identities](runs.json) and [tools](tools.json) record separate
validation levels. Unresolved platform capability warnings remain; structural checks do not prove pixel fidelity
or formal acceptance. No preferences, font data, user checkpoints, overlay lifecycle or launch flag were changed.
