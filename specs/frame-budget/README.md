# Rain frame budget

Latest MatrixRain storage bindings: [2026-11-16 retained-capacity review](validation/2026-11-16-storage/README.md).

Previous shader bindings: [2026-11-16 SDK/shader baseline](validation/2026-11-16-sdk-gpu/README.md).
Prior dated source validation remains historical; descriptive-draft acceptance is unchanged.

Previous CPU-only `MatrixRain` baseline (before the shader change):
[2026-11-16 CPU/GPU baseline](validation/2026-11-16-cpu-gpu/README.md).
Earlier dated results below remain historical for changed renderer source;
requirements and descriptive-draft acceptance are unchanged. Official HC/SpecPM
validation of this candidate is pending because those tools are unavailable.

[Contract](specs/budget.spec.yaml), [map](../hypercode/frame-budget.hc),
[validation](validation/2026-11-03/README.md).

Low Power Mode requests 30 fps on macOS and tvOS. Glow above zero also keeps the historical 30 fps request. With Glow
at zero the renderer follows its screen's maximum refresh, capped at 120 fps, and
re-evaluates after window attachment or a move to another display. Halo work below
a 1/16384 coverage floor is skipped both on the CPU (instances) and in the diffuse
fragment (before light-cloud noise); offscreen renders are pixel-identical to the
previous shader. The first-tried 1/512 floor changed near-black skirts by up to
15/255 and was rejected. This is a descriptive draft; windowed macOS probe numbers
do not establish fullscreen, power or Apple TV device performance.
