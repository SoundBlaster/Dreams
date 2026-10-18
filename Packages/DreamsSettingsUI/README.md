# Dreams native settings catalog

Stage one of the native settings migration: a standalone macOS SwiftUI application
and a small composition library. The separately launched catalog remains independent of the production target.
The production app now links only the small UI library and offers a SwiftUI settings
host under the explicit, default-off `--native-settings` launch flag. See
[host scope and limits](../../specs/settings-host/README.md).

## Build and open

From the repository root:

```sh
make settings-catalog
make settings-catalog-run
python3 scripts/test-settings-catalog.py
```

The app is `dist/DreamsSettingsCatalog.app`, with its own bundle identifier
`ru.egormerkushev.dreams.settings-catalog`. Minimum deployment is macOS 15.
The package has no external dependencies. `swift build --package-path
Packages/DreamsSettingsUI --target DreamsSettingsUI` also builds the library independently.

## Catalog

- **Controls:** system buttons, checkbox/switch Toggle styles, menu/segmented Pickers,
  ColorPicker, Slider, Stepper, TextField, TextEditor and ProgressView; actions only
  open a fixture alert.
- **Settings Form:** grouped Form/Section composition with fixture values. Columns
  24–240, speed 0.1–3×, acceleration −120–0 rows/s² and search 0–100% demonstrate
  the current controls' units. These values are not production defaults. Automatic
  columns and braking exercise dependent disabled controls. Reset resets this page only.
- **Navigation:** the real NavigationSplitView sidebar, DisclosureGroup, system
  inspector and ContentUnavailableView. Selection and options belong to each window.
- **Materials:** shared `SettingsMaterialPanel` with Reduce Transparency / Increase Contrast fallback, native
  `.glass`/`.glassProminent` buttons when macOS 26+ is available, and an uncovered
  content slot. Catalog fixtures stay static and independent of the production rain.
- **Typography:** system text styles, semantic foreground styles, wrapping and
  monospaced numeric readouts.

The toolbar's Catalog Options menu changes system/light/dark appearance, control
size and disabled specimens. It does not write settings. Page fixtures are ephemeral
and may reset when navigating away; sidebar selection stays with the window.
English and Russian resources belong to the catalog target's `Bundle.module`.

## Library boundary

`SettingsSliderRow` composes a system Slider and three aligned HStack columns with a caller-owned
Binding, range, step, formatted readout and accessibility identifier. The host owns
units, input validation and persistence. When space permits, label and track columns share the available space;
readouts use a shared 80-point column scaled with the body text. ViewThatFits moves
the label above the controls in narrow rows, then stacks the readout above the slider
if larger text needs more room. Tracks retain a 120-point minimum. Long labels wrap,
and value changes do not move track endpoints within one layout. `SettingsPreviewRegion` clips an injected
content view; it adds no material, rendering engine, timers or capture behavior.
`SettingsMaterialPanel` composes a system regular material and rounded clipping, using an opaque semantic background for Reduce Transparency or increased contrast. Both catalog and production host use this same surface. It does not own controls, clocks, preferences or a rendering engine.
Do not put the production controller or renderer into this UI package.

## Next stages

1. Add a new settings host under a feature flag that defaults **off**. Keep the
   existing AppKit settings path. The catalog itself is already an opt-in separate app;
   this route is now available only with `--native-settings`; `--legacy-settings` wins
   when both flags are supplied.
2. The new host now binds to the same production controller. General records and
   resets the stop shortcut directly; Advanced retains access to the legacy window.
   Both presentations share the recorder and Carbon registration owner. Validate
   interactive parity before enabling the native host by default.
3. The host now injects one independent production renderer behind the settings detail,
   preserving 100% hosting-display scale with a clipped viewport.
4. The opt-in host now places grouped forms over the shared material panel, leaving
   a clear rain region beside/above them. macOS 26 uses system background extension
   under navigation and a glass playback button; macOS 15 retains standard materials.
   Continue evaluating legibility and accessibility before rollout.
5. Validate parity and performance before separately deciding to enable the new host.

The HTML kit and the NavigationSplitView sample informed composition; their custom
web controls, fonts, mock engine and color-domain model are not dependencies.
This catalog does not assert complete HIG, VoiceOver or visual conformance.

## References

- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Apple: Landmarks](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Catalog draft contract](../../specs/settings-catalog/README.md)
