# Dreams for Apple TV

A standalone tvOS app: film-style Matrix rain with an `HH:mm` clock formed by a brightness mask on the glyph grid. Each glyph is one clock pixel: if its cell center falls inside a digit, the entire glyph brightens. The digit outline never clips the glyph. Diffuse glow remains at the background exposure, so overlapping halos do not form a green digit-shaped cloud. Local time updates once per minute.

The app uses the same `MatrixSimulation.swift`, `Rain.metal` helpers and `DreamsMatrix.ttf` as macOS, through Xcode target membership. The macOS target and its controls remain unchanged. The tvOS renderer has no agent hooks, MCP server or desktop window dependencies.

## Appearance and controls

- 28 reconstructed film glyphs (`U+E001…U+E01C`), with normal and horizontally mirrored variants. Designed Latin/Cyrillic glyphs are excluded.
- Glyphs remain stationary; writing and fading cursors move down each column. A mirror variant persists until the simulation replaces that glyph.
- Film green, occasional pale glyphs, fixed phosphor grain and diffuse glow.
- Select, Play/Pause or Back opens settings. Back or **Show clock** returns to the clock.
- Focus a setting and use Left/Right to adjust it. Values persist between launches.

| Setting | Range | Default |
|---|---|---|
| Columns | 48–160, steps of 4 | 96 |
| Rain density | 10–100%, steps of 5 percentage points | 82% |
| Brightness | 2–35% | 18% |
| Speed | 0.25–3× | 0.43× |
| Fade | 1–16 glyphs | 3 |
| Floating clock | On / Off | On |
| Clock font | System / Rounded / Monospaced | System |
| Clock size | 50–115% | 100% |

Density controls packet length, random gaps and the pause between passes. At 100%, every column wraps immediately and has no random gaps: after a top-to-bottom warmup, all grid cells stay occupied. Fade still controls the sequential dimming at each packet's tail, with a 20% opacity floor at full density until the cursor replaces the glyph. Live density changes take effect as new packets are written, without revealing expired symbols.

Clock motion shifts the sampling positions on a cached brightness mask; it never moves the underlying rain grid. Its slow horizontal and vertical paths are bounded by the measured text extents, leaving a margin at every edge. The mask is rebuilt only when the minute, font, size or screen aspect changes. Each visible glyph needs one bitmap lookup per frame, with no per-fragment clock-mask texture sampling.

The clock runs while Dreams is the foreground app. It is not a replacement for the Apple TV system screensaver. Dreams disables the [idle timer](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled) while the clock is active and restores it in settings or when inactive.

## Build

Requires Xcode with the tvOS SDK, XcodeGen, and a tvOS 18+ simulator/device.

```sh
xcodegen generate --spec tvOS/project.yml
xcodebuild -project tvOS/DreamsTV.xcodeproj -scheme DreamsTV \
  -destination 'generic/platform=tvOS Simulator' \
  -derivedDataPath tvOS/.build CODE_SIGNING_ALLOWED=NO build
```

For tests, select an installed Apple TV simulator:

```sh
xcodebuild -project tvOS/DreamsTV.xcodeproj -scheme DreamsTV \
  -destination 'platform=tvOS Simulator,id=<UDID>' \
  -derivedDataPath tvOS/.build CODE_SIGNING_ALLOWED=NO test
zsh scripts/lint-architecture.sh --root tvOS/Sources
```

The generated project and build artifacts are ignored; `project.yml` is the source of truth. Device installation requires your signing team. The tvOS source tree follows the repository's FSD rules; app composition connects the clock and settings pages.

## Verification

Checked locally on Apple TV 4K (3rd generation, 1080p), tvOS 27 Simulator:

- Twelve unit tests pass, covering actual font loading and runtime Metal shader compilation, whole-glyph selection, minute updates, mask silhouettes, three distinct system fonts at maximum size, preference persistence and bounds, sparse rain and sustained full-grid occupancy at 100% density.
- Remote input opens settings using Select, Play/Pause or Back, changes the values, and returns to the clock using Back or Show clock.
- Columns clamp to 48/160; clock size clamps to 50/115%. Changed preferences survive termination and relaunch.
- The clock consists of illuminated rain glyphs and is upright and readable. All eight settings, the remote hint and Show clock fit on a 1080p screen.
- `make lint`, the FSD regression checks and existing macOS simulation checks pass.

Physical Apple TV performance, TV overscan and readability at viewing distance still need device verification. CI builds the tvOS target; the interactive Simulator checks are local.
