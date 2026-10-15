# Native preview scale integration — 2026-10-15

Runtime `4973f2576232fab2c33398e6c49ce461cd5ad95d`; [current source/map identities](../../evidence/2026-10-15-scale/source-identity.json).
Stable motion/search/head/pulse and overlay session/display/presentation/exit requirements remain applicable.
The native preview supplies a screen-sized reference viewport and clips to its drawable; fullscreen defaults
retain the actual drawable size. This does not change simulation, shader, display selection, input, hooks,
fonts/checkpoints or tvOS. Changed source/maps invalidate the previous current integration identity.

[Fresh host checks and limitations](../../../settings-host/validation/2026-10-15-scale/README.md): 56 unit/Metal tests,
byte-exact GPU crop comparison for auto/manual columns at 1x/2x, CUA scale observation, lint and HC/SpecPM checks.
Older records remain preserved; local preview observations do not establish fullscreen/physical-device acceptance.
