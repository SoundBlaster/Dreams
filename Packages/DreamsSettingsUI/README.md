# Dreams native settings catalog

Stage one of the native settings migration: a standalone macOS SwiftUI application
and a small composition library. The main Dreams app does not depend on this package.
No production settings window, persistence, overlay lifecycle or tvOS code is changed.

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
- **Materials:** standard material with Reduce Transparency fallback, native
  `.glass`/`.glassProminent` buttons when macOS 26+ is available, and an uncovered
  content slot. There is no simulated rain or whole-window glass effect.
- **Typography:** system text styles, semantic foreground styles, wrapping and
  monospaced numeric readouts.

The toolbar's Catalog Options menu changes system/light/dark appearance, control
size and disabled specimens. It does not write settings. Page fixtures are ephemeral
and may reset when navigating away; sidebar selection stays with the window.
English and Russian resources belong to the catalog target's `Bundle.module`.

## Library boundary

`SettingsSliderRow` composes a system Slider and LabeledContent with a caller-owned
Binding, range, step, formatted readout and accessibility identifier. The host owns
units, input validation and persistence. `SettingsPreviewRegion` clips an injected
content view; it adds no material, rendering engine, timers or capture behavior.
Do not put the production controller or renderer into this UI package.

## Next stages

1. Add a new settings host under a feature flag that defaults **off**. Keep the
   existing AppKit settings path. The catalog itself is already an opt-in separate app;
   the production feature flag is deliberately not implemented in stage one.
2. Bind the new host to the same production settings owner and operations.
3. Inject the existing Metal renderer into an embedded preview with independent
   lifecycle. Changes must affect the preview without starting fullscreen rain.
4. Compare Settings-style surfaces with the proposed glass/rain composition, including
   open regions, legibility, light/dark appearance and accessibility settings.
5. Validate parity and performance before separately deciding to enable the new host.

The HTML kit and the NavigationSplitView sample informed composition; their custom
web controls, fonts, mock engine and color-domain model are not dependencies.
This catalog does not assert complete HIG, VoiceOver or visual conformance.

## References

- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Apple: Landmarks](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Catalog draft contract](../../specs/settings-catalog/README.md)
