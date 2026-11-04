/// Shared macOS/tvOS cost policy for the rain renderers.
enum RainFrameBudget {
    static let glowFramesPerSecond = 30
    static let maximumFramesPerSecond = 120
    /// Halo coverage below this stays under half an sRGB step at black for halo colours up to 2.6;
    /// it must match `matrixFragment` in Rain.metal.
    static let minimumHaloAlpha: Float = 1.0 / 16384

    /// Glow keeps the 30 fps budget. Without it the rain follows the screen, capped at 120.
    /// An unknown screen (a view outside a window) keeps the glow budget.
    static func framesPerSecond(glow: Double, screenMaximum: Int) -> Int {
        guard glow <= 0, screenMaximum > 0 else { return glowFramesPerSecond }
        return min(maximumFramesPerSecond, screenMaximum)
    }
}
