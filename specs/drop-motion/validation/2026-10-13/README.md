# Drop deceleration validation — 2026-10-13

Runtime/test source: `984a8a114dc24a38a79bc042b06c1f195be31d64`.
[Source/map identities](../../evidence/2026-10-13/source-identity.json) pin
full files/exact excerpts and current map hashes; historical packages are preserved.
Contracts remain descriptive drafts. HC has no domain contract rules, so its
checks cover syntax/cascade/declarations only, not animation correctness.

- [Unit target](unit.log): make test-unit passed, including analytic motion,
  nine acceleration/density cases, sequential fading, event expiry, full density,
  frame subdivision, mid-packet tuning and disabled/zero-mode parity.
- [Independent legacy witness](legacy-parity.log): main `85e3aee` and current
  default mode produce identical bit-level state digest `9640ee41d84931f5` over
  three densities, 12 columns and 301 timestamps. The [witness](legacy-parity-witness.swift)
  includes trigger duration, scheduling, PRNG and per-cell fields. This is sampled
  parity evidence, not a proof over all possible inputs.
- [Native settings test](native-ui.log): completed successfully; toggle, enabled
  state, negative value, saved/reloaded preferences and disable are asserted.
  The test used an isolated feed and restored changed preferences. The
  [Screener PNG](settings.png) was inspected separately through Screener MCP:
  session FEB95C81-F1E5-432A-9845-25C712D34422, record DFC04DF4-2781-4ADA-BEB5-886BEB780701.
  Its SDK capture completed, while the asynchronous test harness did not report
  a completed test pass. The final synchronous target/action test reports that
  pass separately. UI implementation sources are unchanged between the two runs;
  their test/capture harnesses differ. The malformed synchronous AppKit PNG is
  discarded and is not appearance evidence.
- [Release app build](app.log) and [localization](localization.log) passed. An
  existing glyph venv was reused through a temporary worktree-only symlink.
- Metal frame exports passed for [constant](render-constant.log) and
  [braking](render-braking.log) modes: 100 frames each at 10 fps. A ten-second
  side-by-side movie is in artifacts/drop-deceleration/comparison.mp4 (left:
  constant; right: a=-24 at speed 1×); it is a review artifact outside this package.

[Runs](runs.json) records commands/diagnostics and [tools](tools.json) records
identities. SpecPM/HC, SwiftLint, Markdown and whitespace results are recorded
there. Platform dependency warnings are retained. Native checks establish this
Mac's controls/rendering path, not film fidelity, tvOS adoption or every display.
