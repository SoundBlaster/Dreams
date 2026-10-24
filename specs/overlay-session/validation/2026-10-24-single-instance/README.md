# Desktop ownership / reopening — 2026-10-24

Runtime/test source: `a0cd20994743c20f941414be99b407d9b00cd11c`.
[Current changed-source identities](../../evidence/2026-10-24-single-instance/source-identity.json).

`dreams.overlay.session` and `dreams.overlay.exit` retain their algorithms,
stopForReopen and cleanup obligations. Startup prevents a second desktop
controller from being constructed; explicit reopening may promote an exclusive
accessory owner. Renderer, exit-input and display-selection algorithms are unchanged.

[Current desktop checks](../../../application-menu/validation/2026-10-24-single-instance/README.md)
do not transfer acceptance from historical overlay or physical-device results.
