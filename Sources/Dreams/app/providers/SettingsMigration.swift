import Foundation

/// Early builds used the bundle id `local.dreams.app`. On the first launch under the real id,
/// copy the user's saved look over once, without overwriting anything already set.
enum SettingsMigration {
    static let legacyDomain = "local.dreams.app"
    private static let marker = "migratedFromLegacyDomain"
    private static let keys = [
        "rainDensity", "rainFadeRows", "rainSpeed", "rainBrightnessSpread", "rainGlow", "transparentRainGlow",
        "rainIdleIntensity", "rainColor", "transparentRainColor", "keywordColor", "keywordBrightness",
        "transparentBackground", "restoredGlyphs"
    ]

    static func run(defaults: UserDefaults = .standard, bundleID: String? = Bundle.main.bundleIdentifier) {
        guard let bundleID, bundleID != legacyDomain, !defaults.bool(forKey: marker) else { return }
        defaults.set(true, forKey: marker)
        guard let legacy = defaults.persistentDomain(forName: legacyDomain) else { return }
        for key in keys where defaults.object(forKey: key) == nil {
            if let value = legacy[key] { defaults.set(value, forKey: key) }
        }
    }
}
