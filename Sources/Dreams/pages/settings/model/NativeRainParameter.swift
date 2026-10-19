import Foundation

/// The host owns production units and ranges; DreamsSettingsUI only composes controls.
enum NativeRainParameter: CaseIterable {
    case density, speed, search, deceleration, fade, spread, pulse, glow, idle, keywordBrightness

    @MainActor var keyPath: ReferenceWritableKeyPath<DreamsController, Double> {
        switch self {
        case .density: \.rainDensity
        case .speed: \.rainSpeed
        case .search: \.rainSearchFraction
        case .deceleration: \.rainDeceleration
        case .fade: \.rainFadeRows
        case .spread: \.rainBrightnessSpread
        case .pulse: \.rainPulseStrength
        case .glow: \.rainGlow
        case .idle: \.rainIdleIntensity
        case .keywordBrightness: \.keywordBrightness
        }
    }
    var title: LocalizedStringResource {
        switch self {
        case .density: settingsString("rain.density")
        case .speed: settingsString("rain.speed")
        case .search: settingsString("rain.search")
        case .deceleration: settingsString("rain.deceleration")
        case .fade: settingsString("rain.fade")
        case .spread: settingsString("rain.spread")
        case .pulse: settingsString("rain.pulse")
        case .glow: settingsString("rain.glow")
        case .idle: settingsString("rain.idle")
        case .keywordBrightness: settingsString("words.brightness")
        }
    }
    var help: LocalizedStringResource {
        switch self {
        case .density: settingsString("rain.density.tip")
        case .speed: settingsString("rain.speed.tip")
        case .search: settingsString("rain.search.tip")
        case .deceleration: settingsString("rain.deceleration.tip")
        case .fade: settingsString("rain.fade.tip")
        case .spread: settingsString("rain.spread.tip")
        case .pulse: settingsString("rain.pulse.tip")
        case .glow: settingsString("rain.glow.tip")
        case .idle: settingsString("rain.idle.tip")
        case .keywordBrightness: settingsString("words.brightness.tip")
        }
    }
    var symbol: String {
        switch self {
        case .density: "drop"
        case .speed: "bolt"
        case .search: "magnifyingglass"
        case .deceleration: "arrow.down"
        case .fade: "line.3.horizontal.decrease"
        case .spread: "circle.lefthalf.filled"
        case .pulse: "waveform.path"
        case .glow: "sparkles"
        case .idle: "moon"
        case .keywordBrightness: "sun.max"
        }
    }
    var range: ClosedRange<Double> {
        switch self {
        case .speed: 0.25...3
        case .deceleration: MatrixSimulation.Deceleration.minimumAcceleration...0
        case .fade: 1...16
        case .glow: 0...3
        case .keywordBrightness: 0...2
        default: 0...1
        }
    }
    var step: Double { self == .fade ? 1 : self == .deceleration ? 0.5 : 0.01 }
    var identifier: String {
        switch self {
        case .density: "dreams.rain-density"
        case .speed: "dreams.rain-speed"
        case .search: "dreams.rain-search-fraction"
        case .deceleration: "dreams.rain-deceleration"
        case .fade: "dreams.rain-fade"
        case .spread: "dreams.rain-brightness-spread"
        case .pulse: "dreams.rain-pulse-strength"
        case .glow: "dreams.rain-glow"
        case .idle: "dreams.rain-idle"
        case .keywordBrightness: "dreams.keyword-brightness"
        }
    }
    func readout(_ value: Double, locale: Locale) -> String {
        switch self {
        case .speed: value.formatted(.number.precision(.fractionLength(2)).locale(locale)) + "×"
        case .deceleration: L("rain.deceleration.value", value)
        case .fade: L("rain.fade.value", Int(value))
        default: value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
        }
    }
}

enum NativeSettingsSection: String, CaseIterable, Identifiable {
    case general, appearance, rain, background, words, displays, advanced
    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .general: settingsString("native.section.general")
        case .appearance: settingsString("native.section.appearance")
        case .rain: settingsString("section.rain")
        case .background: settingsString("native.section.background")
        case .words: settingsString("section.words")
        case .displays: settingsString("section.displays")
        case .advanced: settingsString("native.section.advanced")
        }
    }
    var help: LocalizedStringResource {
        switch self {
        case .density: settingsString("rain.density.tip")
        case .speed: settingsString("rain.speed.tip")
        case .search: settingsString("rain.search.tip")
        case .deceleration: settingsString("rain.deceleration.tip")
        case .fade: settingsString("rain.fade.tip")
        case .spread: settingsString("rain.spread.tip")
        case .pulse: settingsString("rain.pulse.tip")
        case .glow: settingsString("rain.glow.tip")
        case .idle: settingsString("rain.idle.tip")
        case .keywordBrightness: settingsString("words.brightness.tip")
        }
    }
    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .rain: "slider.horizontal.3"
        case .background: "square.stack.3d.up"
        case .words: "textformat"
        case .displays: "display"
        case .advanced: "wrench.and.screwdriver"
        }
    }
}
