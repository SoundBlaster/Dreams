# Dreams for Apple TV

A standalone tvOS 18+ foreground app: the same stationary Matrix rain simulation as
macOS, optionally forming an HH:mm clock by brightening whole glyphs. It is not a
replacement for the Apple TV system screensaver. No hooks, MCP server, agent feed,
desktop overlays or display-management dependencies are included.

## Rain parity

Shared target sources are MatrixSimulation, GlyphPulse, DreamsPreset and Rain.metal.
The TV host applies density, speed, fade, simultaneous search, optional deceleration,
brightness spread, real-time independent pulse, rain color and glow. Pale heads remain
bright independently of random ink, keep cycling with trail search at0%, and remain
visible on a packet gap. RGB input is sRGB; the renderer converts it to linear light.

The restored font repertoire is discovered from its private-use characters instead
of hardcoding28 glyphs. The classic Matrix-Code option uses the same repertoire as
macOS. TV retains normal and horizontally mirrored variants. Font resources and
third-party notices are bundled; neither font reconstruction nor these checks assert
film fidelity. See [parity matrix](parity.md) for defaults and platform distinctions.

| Setting | Range | TV default |
|---|---|---|
| Automatic grid | On / Off; 72 rows, aspect-based columns | Off |
| Manual columns | 24–240, step1 | 96 |
| Rain density | 0–100%, step1 point | 82% |
| Brightness | 2–35%, step1 point | 18% |
| Speed | 0.25–3×, step0.01 | 0.43× |
| Fade | 1–16 glyphs | 3 |
| Simultaneously searching glyphs | 0–100%, step1 point | 10% |
| Decelerate drops | On / Off | Off |
| Acceleration | -120–0 glyph/s², step0.5 | -12 |
| Brightness spread / pulse | 0–100%, step1 point | 51% / 30% |
| Glow | 0–300%, step1 point | 57% |
| Rain RGB channels | 0–100%, step1 point | 8.6% / 54.7% / 26% |
| Restored glyphs | On / Off | On |
| Show clock / floating clock | On / Off | On / On |
| Clock font | System / Rounded / Monospaced | System |
| Clock size | 50–115%, step5 points | 100% |

Existing TV preferences retain their keys and values. New preferences fall back to
the shared macOS preset where applicable; existing TV density, brightness and clock
defaults remain unchanged. Reset restores all TV defaults after confirmation.

## Remote and lifecycle

Select, Play/Pause or Back opens settings from the rain. Settings use a scrollable
system List with native Toggles and focusable Button adjustment rows (Slider is not
available on tvOS). Horizontal focus movement adjusts values (directional presses and touch-surface swipes);
Up/Down keeps native row navigation. Select increments a numeric row.
Settings changes immediately affect the rain behind the centered, padded, rounded
material panel. Play/Pause, Back or Show rain closes the open menu. The Live preview
switch separately pauses/resumes rendering while settings are open.
The preview does not create a second simulation or scale the full-screen rain down.

The clock mask brightens ink only; halos stay at background exposure to avoid a
blurred digit-shaped cloud. Clock movement shifts sampling on a cached bitmap,
never the glyph grid. Its mask refreshes on minute/font/size/aspect changes.
Full density retains a dim occupied tail; a zero-opacity glyph is never revived.
The idle timer is disabled only while the foreground rain page is active; it is
restored in settings or when inactive. Rendering also pauses on inactivity, and
teardown releases the Metal view delegate/renderer.

## Build and verification

Requires Xcode with tvOS SDK and XcodeGen. Generated project/build outputs are ignored.
Use Release configuration for physical-device performance checks; simulator/Debug
results do not establish frame rate on older Apple TV hardware.

```sh
make app-tv
make test-tv TV_DEVICE=<Apple-TV-simulator-UDID>
```

Local Egor-host builds use the required TB5 preflight and returned path:

```sh
make app-tv TV_DERIVED_DATA=<verified-checkout-derived-data>
make test-tv TV_DEVICE=<UDID> TV_DERIVED_DATA=<verified-checkout-derived-data> TV_TEST_OPTIONS='-parallel-testing-enabled NO'
```

Explicit product/intermediate roots override global Xcode custom locations, keeping
each worktree's outputs separate. Source checkouts stay in place.

The dated [TV contract and verification](../specs/tvos/README.md) distinguishes unit/
renderer-instance checks, simulator remote interaction, Metal build and physical
Apple TV acceptance. A tvOS check does not establish macOS behavior or vice versa.
Physical device performance, TV overscan/readability and spoken VoiceOver remain
separate verification work.
