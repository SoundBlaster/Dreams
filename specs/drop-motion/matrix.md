# Drop-motion claims and integration

All contract claims are descriptive drafts. User intent is opt-in braking,
unchanged entry speed and one negative-acceleration control. The 20% terminal
speed, numeric range/default and next-packet application are disclosed
implementation choices. Formal acceptance and observed film fidelity are separate.

| Claim | Contribution / owner | Evidence / limit |
| --- | --- | --- |
| opt_in | Simulation keeps the legacy branch when disabled or a=0; GUI defaults off | Historical legacy witness retained; current disabled/zero tests at the same search policy. Search now has an independent PRNG |
| kinematics | Motion.arrival gives decreasing head speed then positive terminal speed | Independent analytic examples and nine acceleration/density cases |
| units_and_validation | Deceleration normalizes input; MatrixRain scales simulation time | Input boundary tests; real-time acceleration S²a assumes constant global speed S |
| deterministic_timing | Row arrival timestamps drive writes/mutations | Fine/coarse timestamp subdivision comparison at full coverage |
| tail_lifecycle | Per-cell captured hold/fade and flight-relative stretch | Sequential fade/expiry, no resurrection and full-density repeated-pass tests; gating can intentionally clear/rest columns |
| stable_packet | Capture at row zero; tuning waits for a new packet | Mid-packet tuning test; existing cells retain their lifetimes |
| bounded_event | trigger returns a bound through final rear expiry | Nine acceleration/density combinations; parent must apply settings before trigger/initial advance |
| parent_assembly | Controller saves tuning; both renderer draw paths forward it before simulation events | Native settings target/action/persistence test; Metal frame export for both modes; settings remain read-only through MCP |

Changing column count rebuilds the grid as before. Changing global speed still
scales the whole simulation clock, including mutation and dissolution, rather
than affecting entry velocity alone. No drag physics, fluid dynamics or exact
movie reconstruction is claimed. Dynamic activity/visibility follows existing
policies; the deterministic path test holds those inputs constant.

Current integrated baseline: [2026-10-14 motion-stack](validation/2026-10-14-motion-stack/README.md). Prior source/test records remain historical.

Current search-policy source and validation are linked in [search claims](search-matrix.md).
The original PRNG parity result identifies its old baseline only. Motion claim IDs stay stable;
opt_in now explicitly scopes parity to the same selected mutation policy.
