# Architecture maps

[Application orientation](application.hc) / [properties](application.hcs) show
three areas from the current checkout: desktop application, agent integrations
and glyph toolchain. Desktop now has an [overlay detail](overlay-session.hc) /
[profiles](overlay-session.hcs) with [draft contracts](../overlay-session/README.md).
Other desktop UI and agent integrations remain unexplored. This is partial
contract coverage, not a complete application specification.

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
The command checks application/editor/overlay maps, both editor profiles and
the four overlay profiles (interactive/agent × opaque/transparent). Tool identity, source
hashes and full diagnostics for the initial recovery are preserved in the
[validation record](../glyph-editor/validation/2026-10-13/README.md).

PR #8 FSD integration refreshes current source paths and represents SettingsPage and
TelevisionApplication as explicitly unexplored leaves. Existing overlay role/claim IDs
remain stable; [new identities](../overlay-session/evidence/2026-10-13-fsd/source-identity.json)
and [validation](../overlay-session/validation/2026-10-13-fsd/README.md) preserve older baselines.

The [drop-motion detail](drop-motion.hc) and [profiles](drop-motion.hcs) recover
optional head deceleration, captured tail lifetimes and event duration. Validate
default and `motion=decelerating`; rendering outside that boundary stays unexplored.
The [drop-motion package](../drop-motion/README.md) records units and runtime evidence.

The [glyph-search detail](glyph-search.hc) / [profiles](glyph-search.hcs) describe
simultaneous live-cell occupancy; validate default, search=disabled and search=saturated.
Its [draft capability](../drop-motion/specs/search.spec.yaml) shares the rain simulation
package with motion. Neither map establishes shader/atlas or tvOS behavior.

The [settings catalog](settings-catalog.hc) / [properties](settings-catalog.hcs)
describe a separately launched SwiftUI showcase with a [draft contract](../settings-catalog/README.md).
It adds a sibling application role without changing DesktopApplication.SettingsPage.
Production settings migration and embedded rendering remain explicit next-stage work.
