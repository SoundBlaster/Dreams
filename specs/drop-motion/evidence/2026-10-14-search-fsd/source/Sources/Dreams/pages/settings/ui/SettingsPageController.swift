// Sources/Dreams/pages/settings/ui/SettingsPageController.swift:21-37
    var hookStatusLabels: [String: NSTextField] = [:]
    var hookButtons: [String: NSButton] = [:]
    var glowSlider: NSSlider?
    var rainColorWell: NSColorWell?
    /// The settings controls by accessibility identifier, so a reset can bring them all up to date.
    var controlsByID: [String: NSControl] = [:]
    let speedLabel = NSTextField(labelWithString: "")
    let searchFractionLabel = NSTextField(labelWithString: "")
    let decelerationLabel = NSTextField(labelWithString: "")
    let brightnessSpreadLabel = NSTextField(labelWithString: "")
    let controller: DreamsController
    var onHotkeyChange: (() -> Void)?

    init(controller: DreamsController) {
        self.controller = controller
        super.init()
    }
// Sources/Dreams/pages/settings/ui/SettingsPageController.swift:58-75

    func refreshValueLabels() {
        columnsLabel.stringValue = String(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount)
        (controlsByID["dreams.rain-columns"] as? NSSlider)?.isEnabled = controller.rainColumnCount != 0
        densityLabel.stringValue = "\(Int((controller.rainDensity * 100).rounded()))%"
        speedLabel.stringValue = String(format: "%.2f×", controller.rainSpeed)
        searchFractionLabel.stringValue = "\(Int((controller.rainSearchFraction * 100).rounded()))%"
        decelerationLabel.stringValue = L("rain.deceleration.value", controller.rainDeceleration)
        (controlsByID["dreams.rain-deceleration"] as? NSSlider)?.isEnabled = controller.rainDecelerationEnabled
        fadeLabel.stringValue = L("rain.fade.value", Int(controller.rainFadeRows))
        brightnessSpreadLabel.stringValue = "\(Int((controller.rainBrightnessSpread * 100).rounded()))%"
        glowLabel.stringValue = "\(Int((controller.rainGlow * 100).rounded()))%"
        idleLabel.stringValue = "\(Int((controller.rainIdleIntensity * 100).rounded()))%"
        keywordBrightnessLabel.stringValue = "\(Int((controller.keywordBrightness * 100).rounded()))%"
    }

    func refreshActivityLabel() {
// Sources/Dreams/pages/settings/ui/SettingsPageController.swift:217-234
    func syncControls() {
        func slider(_ id: String, _ value: Double) { (controlsByID[id] as? NSSlider)?.doubleValue = value }
        slider("dreams.rain-columns", Double(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount))
        (controlsByID["dreams.rain-columns-auto"] as? NSButton)?.state = controller.rainColumnCount == 0 ? .on : .off
        slider("dreams.rain-density", controller.rainDensity)
        slider("dreams.rain-speed", controller.rainSpeed)
        slider("dreams.rain-search-fraction", controller.rainSearchFraction)
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
// Sources/Dreams/pages/settings/ui/SettingsPageController.swift:272-298
    }

    @objc func changeGlow(_ sender: NSSlider) {
        controller.rainGlow = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeDecelerationEnabled(_ sender: NSButton) {
        controller.rainDecelerationEnabled = sender.state == .on
        refreshValueLabels()
    }

    @objc func changeDeceleration(_ sender: NSSlider) {
        controller.rainDeceleration = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeSearchFraction(_ sender: NSSlider) {
        controller.rainSearchFraction = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeSpeed(_ sender: NSSlider) {
        controller.rainSpeed = sender.doubleValue
        refreshValueLabels()
    }

// End of source excerpts.
