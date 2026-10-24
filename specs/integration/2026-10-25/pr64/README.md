# pr64 combined-stack integration

Runtime/source baseline `713c518a4a713820107b600b669cb6019d03bc0f`. Merge preserves both incoming histories, stable claim IDs and accepted product behavior. [Source identities](source-identity.json) refresh only full-file bindings that differ from combined source. Historical tests and device/performance observations are retained and not relabelled as results for this revision.

Structural checks and current-source comparison are recorded in [checks](checks.json). Final pushed-head CI is checked before merge; local structure does not prove physical TV performance or release acceptance.

The previous hosted run stalled after compilation without test output. The exact remote cause was not established. Desktop startup again uses a synchronous main; only the compatibility handoff to an older GUI uses async work. The cross-process lease test uses PATH-selected Python, nonblocking reads and five-second readiness/termination bounds, avoiding an unbounded main-actor wait. Stable `dreams.desktop.single_instance` admission/lifetime/reopen requirements remain unchanged.

Combined-source local tests report101 tests in24 suites passed. Packaged app probes again elect one of six cold launchers, exit six warm duplicates, reject competing full-control/lab launches and preserve two independent publishers. Source and profile identity are recorded separately from historical UI/physical-device observations.
