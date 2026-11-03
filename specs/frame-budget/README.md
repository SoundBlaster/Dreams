# Rain frame budget

[Contract](specs/budget.spec.yaml), [map](../hypercode/frame-budget.hc),
[validation](validation/2026-11-03/README.md).

Glow above zero keeps the historical 30 fps request on macOS and tvOS. With Glow
at zero the renderer follows its screen's maximum refresh, capped at 120 fps, and
re-evaluates after window attachment or a move to another display. Halo work below
a 1/16384 coverage floor is skipped both on the CPU (instances) and in the diffuse
fragment (before light-cloud noise); offscreen renders are pixel-identical to the
previous shader. The first-tried 1/512 floor changed near-black skirts by up to
15/255 and was rejected. This is a descriptive draft; windowed macOS probe numbers
do not establish fullscreen, power or Apple TV device performance.
