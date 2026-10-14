// Sources/Dreams/DreamsController.swift: 17-19
    static let speed = 0.43
    static let decelerationEnabled = false
    static let deceleration = MatrixSimulation.Deceleration.defaultAcceleration

// Sources/Dreams/DreamsController.swift: 157-181
    func resetToDefaults() throws {
        let defaults = UserDefaults.standard
        for key in ["rainColor", "transparentRainColor", "rainGlow", "transparentRainGlow"] {
            defaults.removeObject(forKey: key)
        }
        try setTransparentBackground(DreamsPreset.transparentBackground)
        rainGlow = Self.storedGlow(transparent: transparentBackground)
        rainColor = Self.storedRainColor(transparent: transparentBackground)
        rainColumnCount = DreamsPreset.columnCount
        rainDensity = DreamsPreset.density
        rainFadeRows = DreamsPreset.fadeRows
        rainSpeed = DreamsPreset.speed
        rainDecelerationEnabled = DreamsPreset.decelerationEnabled
        rainDeceleration = DreamsPreset.deceleration
        rainBrightnessSpread = DreamsPreset.brightnessSpread
        rainIdleIntensity = DreamsPreset.idleIntensity
        let words = DreamsPreset.keywordColor
        keywordColor = NSColor(srgbRed: words[0], green: words[1], blue: words[2], alpha: 1)
        keywordBrightness = DreamsPreset.keywordBrightness
        try setRestoredGlyphs(DreamsPreset.restoredGlyphs)
        setHideFromScreenshots(DreamsPreset.hideFromScreenshots)
        runTimeSeconds = DreamsPreset.runTimeSeconds
        stopHotkey = .standard
        try setDisplaySelection(RainDisplaySelection())
    }

// Sources/Dreams/DreamsController.swift: 280-311
    var rainSpeed: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSpeed") as? Double ?? DreamsPreset.speed
        return value.isFinite ? min(3, max(0.25, value)) : DreamsPreset.speed
    }() {
        didSet {
            UserDefaults.standard.set(rainSpeed, forKey: "rainSpeed")
            screenManager.renderers.forEach { $0.rainSpeed = rainSpeed }
        }
    }

    var rainDecelerationEnabled = UserDefaults.standard.object(forKey: "rainDecelerationEnabled") as? Bool
        ?? DreamsPreset.decelerationEnabled {
        didSet {
            UserDefaults.standard.set(rainDecelerationEnabled, forKey: "rainDecelerationEnabled")
            updateDeceleration()
        }
    }
    var rainDeceleration: Double = {
        let value = UserDefaults.standard.object(forKey: "rainDeceleration") as? Double ?? DreamsPreset.deceleration
        return MatrixSimulation.Deceleration(acceleration: value).acceleration
    }() {
        didSet {
            UserDefaults.standard.set(rainDeceleration, forKey: "rainDeceleration")
            updateDeceleration()
        }
    }
    private var dropDeceleration: MatrixSimulation.Deceleration {
        .init(enabled: rainDecelerationEnabled, acceleration: rainDeceleration)
    }
    private func updateDeceleration() {
        screenManager.renderers.forEach { $0.rainDeceleration = dropDeceleration }
    }

// Sources/Dreams/DreamsController.swift: 444-446
            "rain_speed": rainSpeed,
            "rain_deceleration_enabled": rainDecelerationEnabled,
            "rain_deceleration": dropDeceleration.acceleration,

// Sources/Dreams/DreamsController.swift: 505-518
    private func configureRenderer(_ renderer: RainRenderer) {
        renderer.keywordTint = keywordTint
        renderer.rainTint = rainTint
        renderer.keywordBrightness = keywordBrightness
        renderer.rainIdleIntensity = rainIdleIntensity
        renderer.rainGlow = rainGlow
        renderer.rainSpeed = rainSpeed
        renderer.rainDeceleration = dropDeceleration
        renderer.rainBrightnessSpread = rainBrightnessSpread
        renderer.rainFadeRows = rainFadeRows
        renderer.rainColumnCount = rainColumnCount
        renderer.rainDensity = rainDensity
        renderer.brightness = Float(lastBrightness)
    }
