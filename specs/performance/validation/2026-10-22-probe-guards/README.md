# Probe guard verification — 2026-10-22 UTC

Current runtime checkpoint: `32ebeb5298f66766cca4673b7b4a905da17e425f`.
The [15-run hardware baseline](../2026-10-22-baseline/README.md) remains pinned to
`6cc029c`; it is not new-SHA execution evidence.

The follow-up changes set the monotonic origin before window activation, reject
pre-start draws and an already-existing output file, and preserve absent CPU
summary metrics as null. The summary accepts gzip evidence. Renderer/simulation
algorithms and all four probe claim IDs remain unchanged. Current bindings reuse
unchanged baseline snapshots and replace only the changed probe/summary sources;
[the source audit](source-audit.json) checks 28 snapshot digests and revision/map
identity with no mismatches.

## Checks

[Command exits](validation-commands.json) retain the verification boundary.
[Existing-output rejection](overwrite-rejection.json) returned exit 1 and preserved
the sentinel file without launching a diagnostic window. Final
[lint](logs/final-lint.log) includes links in all 132 tracked Markdown files;
[specification checks](logs/final-specs.log) also exited 0 after the documents were staged.

- `make app` with TB5 SwiftPM/cache overrides: exit 0,
  [Release build](logs/dreams-perf-guards-build.log).
- Seven isolated suite/filter processes with `DREAMS_TEST_METAL=1`, each with a new
  empty mailbox: all exit 0; [result list](isolated-tests.json) links their logs by
  filename under logs. Eighteen test functions executed, with parameterized image
  cases; the opt-in trail **video capture** test was skipped. The five probe tests
  and pixel-exact crop all passed. [Executed orchestration](isolated-checks-executed.py)
  retains the filters, paths and environment; its host paths are historical.
- A combined parallel attempt had one pixel-exact crop failure:
  [retained failed log](logs/dreams-perf-guards-regression.log). Source inspection
  finds that transparent-fade keyword cases publish/clear messages in the same
  process-wide mailbox used by the crop test. The crop's two separate renderers
  can therefore see different inputs. The isolated runs remove that shared input;
  the failed attempt is not represented as a pass or as a renderer regression.
- `python3 scripts/test-performance-reports.py`: exit 0,
  [report-format check](logs/report-tests.log), including missing values, invalid
  runs and archived gzip input.
- `make lint`: exit 0, [lint](logs/dreams-perf-guards-lint.log). Existing
  SwiftLint `unused_import` analyzer-placement warning remains.
- `make specs-check HYPERCODE=<local executable>`: exit 0,
  [structural checks](logs/dreams-perf-guards-specs.log).
  [Tool identity](tools.json) records SpecPM 0.2.0 and the Hypercode executable
  digest (this Hypercode build does not implement --version). External-provider
  and draft warnings do not establish accepted contracts.
- Bounded 1-second warmup / 3-second collection [smoke](smoke/manifest.json):
  valid, exit 0, explicitly **not a baseline**. Binary/resource digests and source
  status are retained. No new numerical performance claim follows from this run.

Build products and supported caches were routed to the verified TB5 SSD, separate
from other checkouts. Normal installed-app preferences were not edited. After all
onscreen checks, the original `/Applications/Dreams.app` session was restarted
through its Start Matrix button. Accessibility observation confirmed the
`Dreams Rain · Built-in Retina Display` window and Exit action. Screenshot hiding
remained enabled; this is lifecycle/UI evidence, not a new visual acceptance.

This draft probe boundary has structural/source/test evidence only. Instrumentation
overhead calibration, memory/allocator/energy data, agent-event latency, fullscreen,
multiple displays and physical tvOS execution remain explicit backlog.
