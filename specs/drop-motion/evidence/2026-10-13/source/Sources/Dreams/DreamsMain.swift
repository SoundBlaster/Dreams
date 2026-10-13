// Sources/Dreams/DreamsMain.swift: 240-241
    private let speedLabel = NSTextField(labelWithString: "")
    private let decelerationLabel = NSTextField(labelWithString: "")

// Sources/Dreams/DreamsMain.swift: 327-364
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
                sliderRow(L("rain.glow"), value: controller.rainGlow, min: 0, max: 3,
                          action: #selector(changeGlow(_:)), valueLabel: glowLabel,
                          identifier: "dreams.rain-glow",
                          tip: L("rain.glow.tip")),
            ])

// Sources/Dreams/DreamsMain.swift: 585-598
    private func refreshValueLabels() {
        columnsLabel.stringValue = String(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount)
        (controlsByID["dreams.rain-columns"] as? NSSlider)?.isEnabled = controller.rainColumnCount != 0
        densityLabel.stringValue = "\(Int((controller.rainDensity * 100).rounded()))%"
        speedLabel.stringValue = String(format: "%.2f×", controller.rainSpeed)
        decelerationLabel.stringValue = L("rain.deceleration.value", controller.rainDeceleration)
        (controlsByID["dreams.rain-deceleration"] as? NSSlider)?.isEnabled = controller.rainDecelerationEnabled
        fadeLabel.stringValue = L("rain.fade.value", Int(controller.rainFadeRows))
        brightnessSpreadLabel.stringValue = "\(Int((controller.rainBrightnessSpread * 100).rounded()))%"
        glowLabel.stringValue = "\(Int((controller.rainGlow * 100).rounded()))%"
        idleLabel.stringValue = "\(Int((controller.rainIdleIntensity * 100).rounded()))%"
        keywordBrightnessLabel.stringValue = "\(Int((controller.keywordBrightness * 100).rounded()))%"
    }

// Sources/Dreams/DreamsMain.swift: 772-795
    private func syncControls() {
        func slider(_ id: String, _ value: Double) { (controlsByID[id] as? NSSlider)?.doubleValue = value }
        slider("dreams.rain-columns", Double(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount))
        (controlsByID["dreams.rain-columns-auto"] as? NSButton)?.state = controller.rainColumnCount == 0 ? .on : .off
        slider("dreams.rain-density", controller.rainDensity)
        slider("dreams.rain-speed", controller.rainSpeed)
        slider("dreams.rain-deceleration", controller.rainDeceleration)
        (controlsByID["dreams.rain-deceleration-enabled"] as? NSButton)?.state = controller.rainDecelerationEnabled ? .on : .off
        slider("dreams.rain-fade", controller.rainFadeRows)
        slider("dreams.rain-brightness-spread", controller.rainBrightnessSpread)
        slider("dreams.rain-glow", controller.rainGlow)
        slider("dreams.rain-idle", controller.rainIdleIntensity)
        slider("dreams.keyword-brightness", controller.keywordBrightness)
        (controlsByID["dreams.rain-color"] as? NSColorWell)?.color = controller.rainColor
        (controlsByID["dreams.keyword-color"] as? NSColorWell)?.color = controller.keywordColor
        (controlsByID["dreams.transparent-background"] as? NSButton)?.state = controller.transparentBackground ? .on : .off
        (controlsByID["dreams.restored-glyphs"] as? NSButton)?.state = controller.restoredGlyphs ? .on : .off
        (controlsByID["dreams.hide-from-screenshots"] as? NSButton)?.state = controller.hideFromScreenshots ? .on : .off
        if let popup = controlsByID["dreams.run-time"] as? NSPopUpButton,
           let index = DreamsPreset.runTimeChoices.firstIndex(of: controller.runTimeSeconds) { popup.selectItem(at: index) }
        refreshRunTimeHint()
        refreshValueLabels()
    }

// Sources/Dreams/DreamsMain.swift: 833-841
    @objc private func changeDecelerationEnabled(_ sender: NSButton) {
        controller.rainDecelerationEnabled = sender.state == .on
        refreshValueLabels()
    }

    @objc private func changeDeceleration(_ sender: NSSlider) {
        controller.rainDeceleration = sender.doubleValue
        refreshValueLabels()
    }
