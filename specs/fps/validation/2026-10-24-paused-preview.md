# Paused TV stills — 2026-10-24

Runtime baseline `734bb95`: requested paused TV frames omit the readout and
completion callbacks. Continuous rendering still uses successful GPU-completion
intervals; resume resets the window. Shared sampling and macOS behavior stay
unchanged. [TV validation](../../tvos/validation/2026-10-24-paused-preview/README.md)
records source identities, 19 Simulator tests and scoped UI/device evidence.
