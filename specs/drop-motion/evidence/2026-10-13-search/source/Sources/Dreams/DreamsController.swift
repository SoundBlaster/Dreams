// Sources/Dreams/DreamsController.swift:10-24
}

/// The default look: what a first launch (or a missing setting) falls back to.
enum DreamsPreset {
    static let columnCount = 0 // Automatic grid based on the display aspect ratio.
    static let density = 0.0
    static let fadeRows = 3.0
    static let speed = 0.43
    static let searchFraction = 0.1
    static let decelerationEnabled = false
    static let deceleration = MatrixSimulation.Deceleration.defaultAcceleration
    static let brightnessSpread = 0.51
    static let glow = 0.57
    static let transparentGlow = 0.0
    static let idleIntensity = 0.77
// Sources/Dreams/DreamsController.swift:157-184
    /// Every setting back to `DreamsPreset`, for both backgrounds. Live renderers follow at once.
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
        rainSearchFraction = DreamsPreset.searchFraction
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

// Sources/Dreams/DreamsController.swift:280-327
    }

    var rainSpeed: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSpeed") as? Double ?? DreamsPreset.speed
        return value.isFinite ? min(3, max(0.25, value)) : DreamsPreset.speed
    }() {
        didSet {
            UserDefaults.standard.set(rainSpeed, forKey: "rainSpeed")
            screenManager.renderers.forEach { $0.rainSpeed = rainSpeed }
        }
    }

    var rainSearchFraction: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSearchFraction") as? Double ?? DreamsPreset.searchFraction
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.searchFraction
    }() {
        didSet {
            UserDefaults.standard.set(rainSearchFraction, forKey: "rainSearchFraction")
            screenManager.renderers.forEach { $0.rainSearchFraction = rainSearchFraction }
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

    var rainBrightnessSpread: Double = {
        let value = UserDefaults.standard.object(forKey: "rainBrightnessSpread") as? Double ?? DreamsPreset.brightnessSpread
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.brightnessSpread
// Sources/Dreams/DreamsController.swift:450-465
            },
            "transparent_background": transparentBackground,
            "hidden_from_screenshots": hideFromScreenshots,
            "rain_columns": rainColumnCount,
            "rain_density": rainDensity,
            "rain_fade_rows": rainFadeRows,
            "rain_speed": rainSpeed,
            "rain_search_fraction": rainSearchFraction,
            "rain_deceleration_enabled": rainDecelerationEnabled,
            "rain_deceleration": dropDeceleration.acceleration,
            "rain_brightness_spread": rainBrightnessSpread,
            "rain_glow": rainGlow,
            "keyword_color_rgb": [keywordTint.x, keywordTint.y, keywordTint.z],
            "rain_color_rgb": [rainTint.x, rainTint.y, rainTint.z],
            "keyword_brightness": keywordBrightness,
            "rain_idle_intensity": rainIdleIntensity,
// Sources/Dreams/DreamsController.swift:515-540
        if !transparentBackground { stop(reason: .reopen) }
    }

    private func configureRenderer(_ renderer: RainRenderer) {
        renderer.keywordTint = keywordTint
        renderer.rainTint = rainTint
        renderer.keywordBrightness = keywordBrightness
        renderer.rainIdleIntensity = rainIdleIntensity
        renderer.rainGlow = rainGlow
        renderer.rainSpeed = rainSpeed
        renderer.rainSearchFraction = rainSearchFraction
        renderer.rainDeceleration = dropDeceleration
        renderer.rainBrightnessSpread = rainBrightnessSpread
        renderer.rainFadeRows = rainFadeRows
        renderer.rainColumnCount = rainColumnCount
        renderer.rainDensity = rainDensity
        renderer.brightness = Float(lastBrightness)
    }

    private func begin(duration: Double?, brightness: Double) throws {
        guard !screenManager.targetScreens.isEmpty else {
            throw DreamsError.unavailable(L("display.none"))
        }
        stop(reason: .restart)
        lastDuration = duration
        lastBrightness = brightness
