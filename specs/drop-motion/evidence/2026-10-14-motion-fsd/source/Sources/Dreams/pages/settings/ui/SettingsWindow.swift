// Sources/Dreams/pages/settings/ui/SettingsWindow.swift:64-103
            rainColorWell = rainColor
            controlsByID["dreams.rain-color"] = rainColor
            let automaticColumns = NSButton(checkboxWithTitle: L("rain.columns.auto"), target: self,
                                            action: #selector(changeAutomaticColumns(_:)))
            automaticColumns.state = controller.rainColumnCount == 0 ? .on : .off
            automaticColumns.setAccessibilityIdentifier("dreams.rain-columns-auto")
            controlsByID["dreams.rain-columns-auto"] = automaticColumns
            let deceleration = NSButton(checkboxWithTitle: L("rain.deceleration.enabled"), target: self,
                                         action: #selector(changeDecelerationEnabled(_:)))
            deceleration.state = controller.rainDecelerationEnabled ? .on : .off
            deceleration.setAccessibilityIdentifier("dreams.rain-deceleration-enabled")
            deceleration.toolTip = L("rain.deceleration.enabled.tip")
            controlsByID["dreams.rain-deceleration-enabled"] = deceleration
            let rain = settingsGrid([
                [Self.name(L("rain.grid")), automaticColumns, NSView()],
                sliderRow(L("rain.columns"), value: Double(controller.rainColumnCount == 0
                          ? controller.automaticColumnCount : controller.rainColumnCount), min: 24, max: 240,
                          action: #selector(changeColumns(_:)), valueLabel: columnsLabel,
                          identifier: "dreams.rain-columns", tip: L("rain.columns.tip")),
                [Self.name(L("label.color")), rainColor, NSView()],
                sliderRow(L("rain.density"), value: controller.rainDensity, min: 0, max: 1,
                          action: #selector(changeDensity(_:)), valueLabel: densityLabel,
                          identifier: "dreams.rain-density",
                          tip: L("rain.density.tip")),
                sliderRow(L("rain.speed"), value: controller.rainSpeed, min: 0.25, max: 3,
                          action: #selector(changeSpeed(_:)), valueLabel: speedLabel,
                          identifier: "dreams.rain-speed", tip: L("rain.speed.tip")),
                [NSView(), deceleration, NSView()],
                sliderRow(L("rain.deceleration"), value: controller.rainDeceleration,
                          min: MatrixSimulation.Deceleration.minimumAcceleration, max: 0,
                          action: #selector(changeDeceleration(_:)), valueLabel: decelerationLabel,
                          identifier: "dreams.rain-deceleration", tip: L("rain.deceleration.tip")),
                sliderRow(L("rain.fade"), value: controller.rainFadeRows, min: 1, max: 16,
                          action: #selector(changeFade(_:)), valueLabel: fadeLabel, ticks: 16,
                          identifier: "dreams.rain-fade",
                          tip: L("rain.fade.tip")),
                sliderRow(L("rain.spread"), value: controller.rainBrightnessSpread, min: 0, max: 1,
                          action: #selector(changeBrightnessSpread(_:)), valueLabel: brightnessSpreadLabel,
                          identifier: "dreams.rain-brightness-spread",
                          tip: L("rain.spread.tip")),
