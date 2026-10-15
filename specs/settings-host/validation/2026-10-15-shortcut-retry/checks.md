# Verification and limits

- Regression on prior implementation fails exactly at the successful Carbon event dispatch
  assertion ([before](regression-before.log)); the UI registered flag alone had passed.
- [After fix](tests.log): 16 NativeSettingsTests pass. The new regression reserves an unusual
  test-only chord, forces startup failure, releases the conflict, records the unchanged shortcut,
  verifies registration/preferences and dispatches a Carbon hotkey event to the application target.
  Dispatch succeeds after retry and is unhandled before retry/after uninstall. No physical keys,
  fullscreen windows or cross-application delivery claim is made. The original controller stop callback
  is unchanged. Existing controlled-conflict tests still pass. No new full GPU suite run.
- [Lint](lint.log) passes; known unused_import SwiftLint configuration warning remains.
- [HC/SpecPM structure](structure.log) passes (exit 0); `check-identities.py` passes with 127 source/map and snapshot SHA256 pairs.

Commands: `swift test -c release --scratch-path <TB5>/swiftpm --cache-path /Volumes/TB5/Developer/Caches/swiftpm --filter retryAfterStartupConflictRestoresCarbonEventHandler`
(before: exit 1), then same flags with `--filter NativeSettingsTests` (after: exit 0).
`DREAMS_FEED_DIRECTORY=/tmp/dreams-shortcut-retry-feed`; Swift 6.4 / Testing 2084.
TB5 preflight passed for UUID 04B9F65E-894C-4A7C-B517-FC542E8D8E36 and checkout key
Dreams-36273a9c832f69b9. Supported SwiftPM outputs/caches and lint Python/ruff/module caches
use that verified SSD. Existing local artifacts were preserved. CI is not watched or claimed.

Existing fallible rollback (O2) remains explicitly separate from this startup-retry correction.
