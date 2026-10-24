# Desktop ownership / reopening — 2026-10-24

Runtime/test source: `a0cd20994743c20f941414be99b407d9b00cd11c`.
[Current changed-source identities](../../evidence/2026-10-24-single-instance/source-identity.json).

`dreams.settings.host/preview_reopen` replaces only a previously closed Metal
canvas on reopening, explicitly resets the close latch and preserves Play/Pause.
Open-window repeats and adaptive layout retain the current canvas. Existing one-owner,
cleanup, preview-scale and renderer contracts keep their stable IDs. The new
startup lease is owned by the desktop composition, not this settings adapter.

[Executed desktop checks](../../../application-menu/validation/2026-10-24-single-instance/README.md)
separate source/tests, process admission and native rendered motion. Earlier
render/trace results remain historical and are not relabelled for this revision.
