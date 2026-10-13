# Capture-status correction — 2026-10-13

Runtime/test source: `bd5d783e1a6051f663b94d78c26d0c683d3824ab`.
[Source/map identities](../../evidence/2026-10-13-capture-status/source-identity.json)
pin exact current snapshots and inherited unchanged source. The session
contract remains a descriptive draft; acceptance state did not change.

## Runtime evidence

- [CaptureVisibilityTests](capture-status-test.log) passed with both backgrounds
  in the logged-in native AppKit/Metal session. Capture observations/time were
  supplied deterministically; actual native window isVisible, status flags,
  stable ownership/expiry/sleep assertion, the clear grace/reset and cleanup
  were asserted. Settings were restored and the live hook feed was isolated.
- [Negative control](old-calculation-negative-control.log): replacing only
  rain_visible with the original calculation made both background cases fail
  with six visibility expectation failures. Exit 1 is expected evidence that
  the regression catches O1; the corrected source was restored afterwards.
- [Unit target](test-unit.log): make test-unit passed; the native regression is
  opt-in and was run separately above. No physical screenshot-picker detection,
  display topology, keyboard or pixel capture test is claimed.

## Structural evidence

[Runs](runs.json) records commands, exit codes and diagnostics; [tools](tools.json)
records tool identities. All HC maps/profiles and both SpecPM packages pass;
overlay SpecPM retains 0 errors / 11 unresolved-capability warnings, the glyph
package 0 errors / 8 warnings. Markdown links, whitespace and SwiftLint pass
(the pre-existing unused_import configuration notice is unchanged).
These checks establish structure/style, not host capability availability.
The initial and P2-review evidence directories are preserved unchanged.
