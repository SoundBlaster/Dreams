# Simulation allocation and clock formatter baseline

Base: `88e04755c907c8bba319d1b1622c7133133b4e01`, with the source changes in this directory's matching evidence snapshots. These are descriptive draft contracts, not acceptance.

Source SHA-256:

- `MatrixSimulation.swift`: `b87bf050a50348fc190c0dea49f747652bdd56334be321ec91180cba2a981978`
- `ClockMask.swift`: `02f4bda6b94ea505240a500a92fffcd63758b363a65584182d09c31ba210438f`
- `RainParityTests.swift`: `a55aecd416bad122199a8ccaf0f642ca0d3a961bc72ad0be6f08a725b65b9d4d`
- `SearchOccupancyTests.swift`: `4dac313a5acdf0530c7f4986a51c2d5d0a0e04344b267906c293c73e904d2b25`

`dreams.tv.rain/clock` keeps the same time format and auto-updating time zone. `dreams.tv.rain/grid_and_motion`, `dreams.rain.drop_motion`, `dreams.rain.search_occupancy`, `dreams.rain.head_visibility` and the performance claims retain their existing behavior and identities; transferring ownership and omitting a no-op visibility pass do not change the contract. TV renderer assembly remains responsible for supplying live tuning. Historical evidence is not evidence of this revision; relevant implementation snapshots are refreshed. Source and map identities are distinct.

## Checks

- macOS 27, M4 Pro, Swift 6.4: `DREAMS_SWIFT_SCRATCH_PATH=<TB5/swiftpm> DREAMS_SWIFT_CACHE_PATH=/Volumes/TB5/Developer/Caches/swiftpm zsh scripts/swift-macos.sh test -c release`: exit 0, 113 tests passed; opt-in rendering tests were skipped.
- `make test-tv TV_DEVICE=B29EC156-5EF9-4A56-8147-1C98D4E228DB TV_DERIVED_DATA=<TB5/xcode/DerivedData> TV_TEST_OPTIONS='-parallel-testing-enabled NO'`: exit 0, 28 simulator tests passed. The first run had two glow assertions fail because their fixtures assumed the old nonzero default; the corrected fixtures explicitly set glow to 1.
- `make specs-check HYPERCODE=<TB5>/Hypercode-4345ff8dcac12189/swiftpm/arm64-apple-macosx/debug/hypercode`: exit 0; full diagnostics in `specs-check.log`. SpecPM 0.2.0 reports unresolved external capabilities as warnings. Hypercode binary SHA-256 `f9631fa8c2dcfe6c1afd57c4919617e13e84838bfc289fb94440740231684e76`.
- Physical Apple TV HD (AppleTV5,3): Release device build and installation succeeded. Launch was rejected because the device was asleep; FPS and physical behavior were not measured.

## Isolated simulation timings

`simulation-bench.swift` uses 1,800 simulation frames at 50 Hz, density 0.82, search 0.03, acceleration -12 and 72 rows. Compiled with `swiftc -O` separately against base and changed simulation source. Five sequential runs per case on the MacBook Pro M4 Pro; timing is total CPU-side elapsed wall time, not FPS or a controlled device benchmark. No warmup or system-load controls; compare cautiously.

| Columns | Before median | After median | Before/after checksum |
| --- | ---: | ---: | ---: |
| 100 | 112.84 ms | 72.08 ms | 158008 / 158008 |
| 190 | 229.85 ms | 151.72 ms | 312199 / 312199 |

Checksums are coarse witnesses, not proof of complete state equality. The added automated test compares cell glyphs, visibility and write times between implicit and explicit full visibility and checks retained snapshots. The next evidence needed is repeatable Release FPS and frame timing on physical Apple TV under matched settings.
