# Performance measurement — descriptive draft

The [draft contract](specs/measurement.spec.yaml) describes the contributor-facing
opt-in probe. [Usage and limits](../../research/performance/README.md),
[plan](../../research/performance-measurement-plan.md) and
[architecture map](../hypercode/performance.hc) define this bounded first stage.

[Current validation](validation/2026-10-22-calibration/README.md) separates unit/build/
structural checks, rejected probe attempts and actual measurement evidence.
The package does not accept numerical budgets or mark optimization issues solved.

The calibration extension compares full collection against a nil recorder with the
same outer observer. Its [fixed protocol](../../research/performance/calibration-protocol.md)
keeps the common observer cost and historical baseline results separate.
The earlier [15-run baseline](validation/2026-10-22-baseline/README.md) stays historical.
