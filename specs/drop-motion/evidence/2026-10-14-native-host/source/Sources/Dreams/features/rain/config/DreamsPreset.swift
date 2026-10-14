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
    static let keywordColor = [0.0, 1.0, 0.39]
    static let keywordBrightness = 2.0
    static let restoredGlyphs = true
    static let transparentBackground = false
    static let hideFromScreenshots = true
    /// How long the rain runs after Start: 0 means until it is stopped. One hour by default.
    static let runTimeSeconds = 3600.0
    static let runTimeChoices: [Double] = [300, 1800, 3600, 0]
    /// Black background: the classic dark film green. Transparent: a light mint that reads on bright desktops.
    static let rainColor = [0.086, 0.547, 0.26]
    static let transparentRainColor = [0.35, 1.0, 0.55]
}
