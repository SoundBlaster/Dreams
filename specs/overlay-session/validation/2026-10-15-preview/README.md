# Native preview integration — 2026-10-15

Runtime `1c8ba19844fffad464ac7dd7dfce8aba7dac0bb7`; [current source/map identities](../../evidence/2026-10-15-preview/source-identity.json).
The preview receives its own renderer and posed clock; fullscreen draw retains its nil posed-time path.
Shared controller configuration is exposed internally without changing preference or overlay operations.
Stable motion/search/head/pulse and overlay session/display/presentation/exit claim IDs keep their
requirements and draft acceptance. No display/input/hook/font/checkpoint/tvOS behavior changes.

[Fresh host validation, command logs, tools and limitations](../../../settings-host/validation/2026-10-15-preview/README.md)
records 55 local unit/Metal tests, structural checks, actual-app CUA observations and 11 SCK fixture
frames. The fixture capture artifacts are explicitly unaccepted; preview pixels are not fullscreen or
physical-device proof. Changed bindings/maps invalidate earlier current integration identities;
unchanged historical snapshots/tests remain preserved on their original baselines.
