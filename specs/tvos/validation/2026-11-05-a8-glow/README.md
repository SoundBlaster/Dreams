# Apple TV HD glow suspension — 2026-11-05

Descriptive draft; source snapshots and SHA-256 identities are in
`specs/tvos/evidence/2026-11-05-a8-glow/source-identity.json` and the
corresponding FPS and frame-budget evidence directories. The base is
`d1e9881`; changed snapshots are not claimed to be that commit.

- tvOS Simulator Debug `xcodebuild test`, Apple TV 4K 3rd generation,
  selected RainParityTests A8 preference/policy and newer-device preference:
  exit 0, 2 tests passed. This tests injected machine identifiers, not A8 hardware.
- `make specs-check HYPERCODE=/Users/egor/Development/GitHub/0AL/Hypercode/.build/debug/hypercode`:
  exit 0, SpecPM 0.2.0, unresolved external-capability warnings. Hypercode
  SHA-256 `6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`.
- Television HC SHA-256 `de44f06c65b7fd18460ee7f7f2100e733eac3859780495696e5c3c9f4f54e55e`;
  HCS `461198c87dcacad77dfc3ed3712893c6587e28401577ff3cde02113658436539`.
- Physical A8 UI, rendering, FPS, saved-setting retention across app update,
  and 50 versus 60 Hz remain unverified. User's prior build-2 measurements
  are observations, not evidence for this code.
