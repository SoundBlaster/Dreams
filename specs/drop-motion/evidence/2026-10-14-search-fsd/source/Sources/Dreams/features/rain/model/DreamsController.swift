// Sources/Dreams/features/rain/model/DreamsController.swift:132-149
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
// Sources/Dreams/features/rain/model/DreamsController.swift:254-299
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
    }() {
        didSet {
            UserDefaults.standard.set(rainBrightnessSpread, forKey: "rainBrightnessSpread")
// Sources/Dreams/features/rain/model/DreamsController.swift:419-436
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
            "matrix_font": restoredGlyphs ? "restored" : "classic",
            "rain_window_number": overlay.map { $0.windowNumber as Any } ?? NSNull(),
// Sources/Dreams/features/rain/model/DreamsController.swift:487-503
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
// End of source excerpts.
