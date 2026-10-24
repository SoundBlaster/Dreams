# Centered TV settings and Play/Pause exit — 2026-10-21

Runtime `71e0977ed439bae7d7f316186e0c4f032dc71452`. [Source/map identity](../../evidence/2026-10-21-centered-menu/source-identity.json)
pins three changed UI/resource files and the changed television detail map, reusing
unchanged source/map snapshots and font hashes. TV draft.2 changes remote_settings
without altering stable roles, renderer/tuning or platform boundaries.

The user requested a centered settings block, inner spacing, rounded corners and
Play/Pause to hide it. The List has 16-point inner clipping, 24-point panel padding,
1100-point maximum width and 28-point rounded system-material background. The panel
is centered in the available space with 60-point outer margins. Play/Pause closes
open settings rather than pausing its preview. The separate Live preview switch
continues to control rendering. EN/RU guidance now describes menu exit.

[Build](build.log) passed via make app-tv on verified per-checkout TB5 paths.
[Lint](lint.log) passed with the existing unused_import configuration warning.
The initial attempted scrollContentBackground modifier is unavailable on tvOS;
it was removed and native List clipping retained before the successful build.
The previous [17-test run](../2026-10-21-parity/tests.log) remains evidence only for
its previous runtime. These reversible view/remote-route changes are verified by
compilation and focused simulator interaction, not a relabelled old test pass.

[Hypercode/SpecPM validation](structure.log), [source/snapshot identity audit](identity-check.json)
and [documentation links](docs.log) passed. Tool versions match the preceding
[tool identity](../2026-10-21-parity/tools.json); current command results are listed
in [runs.json](runs.json).

The bounded [simulator report](report.md) and [centered-menu screenshot](centered-menu.png)
confirm visible rounded corners and interior gutters. The [menu AX capture](centered-menu-ax.txt)
places the List at (434, 144), size 1052 × 792 on a 1920 × 1080 viewport: its center
is exactly (960, 540). Automatic columns receives native focus; Columns responds
64 → Right 65 → Left 64. [Play/Pause closes the menu](playpause-return-to-rain.png),
leaving [Matrix rain focused without a Table](playpause-return-to-rain-ax.txt).
[Select reopens settings](select-reopened-menu.png), restores Automatic columns focus
and preserves Columns 64 in the [reopened AX capture](select-reopened-menu-ax.txt).
Six capture calls were used; the first was transient launch UI. The verification
session was closed after checking this viewport. No clipping or overlap was observed.

Physical Apple TV, tvOS 18 runtime, spoken VoiceOver, broader locale/matrix and
performance checks remain outside this UI follow-up. Contracts remain descriptive drafts.
