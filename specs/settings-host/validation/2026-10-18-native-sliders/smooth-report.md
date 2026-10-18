# Actual smooth native sliders QA

Fresh Dreams Smooth QA.app supplied by parent, EN Dark.

PASS visual: dense tick marks removed on Columns, Density, Speed, disabled Deceleration and Searching glyphs. Fade sparse marks remain. No cropped labels, controls respond and UI remains alive. Native continuous thumbs are round; this differs visibly from sparse Fade stepped thumb as expected.

PASS AX exact steps and restoration: Density0→0.01/readout1%→0; Speed0.43→0.44→0.43.

PASS short drag rounding/restoration: Density short31px drag produced0.11/readout11%; reverse drag returned0/readout0%. No fractional percent was exposed.

Keyboard limitation: clicking apparent Speed thumb and pressing Right produced no AX change and no reported focused slider. Native keyboard step behavior was not proven; do not claim keyboard parity from AX actions. No repeated keyboard/focus investigation.

Artifacts:
- /tmp/dreams-smooth-sliders-qa/rain.png
- /tmp/dreams-smooth-sliders-qa/rain-ax.txt
- /tmp/dreams-smooth-sliders-qa/ax-step-evidence.txt
- /tmp/dreams-smooth-sliders-qa/keyboard-right-ax.txt
- /tmp/dreams-smooth-sliders-qa/drag-ax.txt
- /tmp/dreams-smooth-sliders-qa/drag-restored-ax.txt

Settings restored to initial values in isolated domain. App left alive on Rain; no production settings, fullscreen overlay or code changes.
