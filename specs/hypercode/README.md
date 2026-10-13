# Architecture maps

[Application orientation](application.hc) / [properties](application.hcs) show
three coarse areas from the current checkout: desktop application, agent
integrations and glyph toolchain. This is an orientation map, not complete
contract coverage. Desktop and agent areas are opaque and still unexplored.

[Glyph editor](glyph-editor.hc) / [properties](glyph-editor.hcs) is the first
recovered subsystem. Its four draft contracts are in the
[glyph workspace package](../glyph-editor/README.md); progress and omitted
areas are tracked in [specification progress](../specification-progress.md).

HC nesting describes composition, not event order/dataflow. HCS source values
are repository-relative bindings, not executable imports. The app/editor does
not load these maps. `mode=standalone` describes a generated editor served
without the checkpoint API; the default describes the local-server profile.
No contract establishes behavior on tvOS; its implementation is on separate
PR #8 and is not imported from unrelated/untracked files into this baseline.

Use `make specs-check` with the tools on PATH. If Hypercode is available only
as a built checkout binary, provide `HYPERCODE=/absolute/path/to/hypercode`.
The command checks both maps and both editor profiles. Tool identity, source
hashes and full diagnostics for the initial recovery are preserved in the
[validation record](../glyph-editor/validation/2026-10-13/README.md).
