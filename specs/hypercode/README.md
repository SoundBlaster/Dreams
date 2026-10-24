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
The original recovery excluded tvOS. Its later [television detail](television.hc) /
[properties](television.hcs) and [draft contract](../tvos/README.md) now describe
the tracked foreground rain/clock/settings host on a separate baseline.

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

The [settings host](settings-host.hc) / [profiles](settings-host.hcs) describe
`settings=legacy` and `settings=native` presentations with the same controller.
[Draft contract](../settings-host/README.md) covers flag routing, bindings and
window lifetime and a window-local embedded Metal backdrop beneath system material
forms and an uncovered region. Full input parity remains next-stage work. Preview has a separate renderer/clock
and uses shared production tuning; see the dated host validation baseline.

The drop-motion detail now includes HeadAppearance, with [current head validation](../drop-motion/validation/2026-10-14-head/README.md).
Other shader/atlas rendering and physical desktop compositing remain unexplored.

[Glyph pulse](glyph-pulse.hc) / [profiles](glyph-pulse.hcs) recover macOS whole-glyph exposure, independent real-time phases and shared strength tuning. Validate default, `pulse=off` and `background=transparent`; tvOS adoption remains excluded.

The television detail covers shared motion/search/pulse adoption and native remote
settings. Validate default and `clock=hidden`. Desktop contracts continue to exclude
TV; a shared source does not transfer macOS execution evidence or acceptance.

The [performance probe](performance.hc) / [properties](performance.hcs) describes
opt-in bounded developer measurements separately from ordinary overlay/settings
lifecycle. [Draft contract](../performance/README.md) and current evidence disclose
hardware/profile limits; instrumentation does not establish optimization gains.

Calibration adds one PerformanceProbe.Calibration responsibility with explicit
`probe=control` and `probe=full` properties. The fixed protocol and current
evidence separate full-collector overhead from the common observer cost.
These contexts describe diagnostic modes, not application configuration.

`probe=feed` adds SyntheticFeed with Publication, SnapshotObservation and
DeliveryProxy roles. The assembly correlates an external atomic publication with
snapshot receipt and actual drawable presentation. It does not promise pixel
verification or make production agent integrations a covered boundary.

The [shared feed reader](keyword-feed.hc) / [properties](keyword-feed.hcs) covers
ready macOS renderer input, background observation and lease lifetime through
[dreams.feed.read](../keyword-feed/README.md). Overlay Renderer.FeedInput composes
this reader; status and legacy session listing remain distinct consumers.
PerformanceProbe.SyntheticFeed.BackgroundReads records attempts independently
from frames, so callback timing does not hide a read in before/after evidence.

[Application menu](application-menu.hc) / [properties](application-menu.hcs) describe
standard interactive macOS commands and their native responder-chain routing.
The [contract](../application-menu/README.md) excludes accessory/TV behavior.

The [FPS readout](fps.hc) / [profiles](fps.hcs) recover the opt-in digit overlay
and its platform-specific timestamp semantics; [contract](../fps/README.md).
