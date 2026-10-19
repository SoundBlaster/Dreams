# Full-width preview help — 2026-10-19

Runtime `84298eb2c4415403c0b7e9d860900953b488d567`. [Source/map identity](../../evidence/2026-10-19-preview-help-width/source-identity.json).

The owner requests the “100% scale…” panel to fill the available preview width
in the compact stacked layout. The help Text now accepts maxWidth infinity with
leading alignment before SettingsMaterialPanel draws its glass background. This
also aligns the footer with the header in wider layouts; 12-point internal insets
remain. No renderer scaling, pane height, navigation or preference change.

Specification impact: stable LivePreview role and material_composition,
independent_preview, preview_scale and one_settings_owner claims remain applicable.
This is a minor presentation refinement folded into material_composition; maps and
contract statements are unchanged. Implementation binding and current identity are
repinned. Prior screenshots/tests remain evidence for their original revisions.
The parent assembly retains one Metal surface, native controls and default-off routing.

Release build passed (Swift helper, TB5 scratch, active SDK27/minos15). No new unit
test mirrors this one-line layout modifier. Structural and actual UI results are
recorded below when complete; no full VoiceOver, macOS15 runtime or release acceptance.

## Structural validation

`make specs-check HYPERCODE=/Users/egor/Development/GitHub/0AL/Hypercode/.build/debug/hypercode` exited0.
[Focused HC/SpecPM log](structure.log) records both host profiles and tool exit codes.
Known descriptive-draft external capability resolution warnings remain.
Hypercode SHA256: `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
SpecPM: `specpm 0.2.0`.

## Actual UI validation

Isolated QA app at an actual700×600 frame, backing scale2.
[Appearance](appearance-700.png) and [Rain](rain-700.png) show the help panel
matching both header edges with leading, wrapped text. Window-size injection was
a temporary QA-only harness; original window source and normal product were
restored byte-for-byte. All57 current/source-map and snapshot hashes match.
Production preferences and system theme were preserved. This does not establish
macOS15 runtime, full accessibility or default-on acceptance.

## Review evidence repair

Preserved the historical [QA harness build log](build.log) and
[Appearance AX](appearance-700-ax.txt)/[Rain AX](rain-700-ax.txt) cited in the
original UI report. Their bytes match the retained QA artifacts. The log is for
the temporary sizing harness, distinct from the separately observed normal build.
Restoration is an operator observation; the retained compiler log does not prove it.
No application, map, contract or runtime-source identity changed.
