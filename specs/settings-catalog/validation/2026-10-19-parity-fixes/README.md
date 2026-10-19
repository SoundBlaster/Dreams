# Direct native slider help — 2026-10-19

Runtime `73417b92aaf89c85b9f1bc7106b1d0fd1ec25691`. [Source/map identity](../../evidence/2026-10-19-parity-fixes/source-identity.json).

Add a source-compatible optional localized help argument to SettingsSliderRow;
apply it directly to both system Slider branches. Omitted help remains empty;
no business state, range, step, formatting or accessibility-value ownership moves
to the library. This fixes observed host row-level help propagation loss.
Stable NativeComponents role and host_owned_binding/native_controls claims
retained. Both consuming-host and catalog bindings repinned; parent still owns
settings and operations. Catalog build passed2.83s on verified nested TB5 scratch.
[Actual host validation](../../../settings-host/validation/2026-10-19-parity-fixes/README.md)
separates UI from structure; standalone catalog UI was not rerun.

Final structural checks: make specs-check exit0. Current source/map/snapshot
identity audit passes25 entries; known draft platform-capability warnings retained.
