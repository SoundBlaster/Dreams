import Foundation
import Observation

enum ClockTypeface: String, CaseIterable {
    case system, rounded, monospaced
    var titleKey: String { "settings.font.\(rawValue)" }
}

struct RainTuning: Equatable {
    static let columnRange = 48...160
    static let brightnessRange = 0.02...0.35
    static let speedRange = 0.25...3.0
    static let fadeRange = 1.0...16.0
    static let clockSizeRange = 0.5...1.15

    var columns = 96
    var brightness = 0.18
    var speed = 0.43
    var fade = 3.0
    var floatingClock = true
    var clockTypeface = ClockTypeface.system
    var clockSize = 1.0

    func normalized() -> Self {
        var result = self
        result.columns = min(Self.columnRange.upperBound, max(Self.columnRange.lowerBound, columns))
        result.brightness = Self.clamp(brightness, to: Self.brightnessRange, fallback: 0.18)
        result.speed = Self.clamp(speed, to: Self.speedRange, fallback: 0.43)
        result.fade = Self.clamp(fade, to: Self.fadeRange, fallback: 3)
        result.clockSize = Self.clamp(clockSize, to: Self.clockSizeRange, fallback: 1)
        return result
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }
}

@MainActor @Observable
final class RainSettings {
    var tuning: RainTuning {
        didSet {
            let value = tuning.normalized()
            if value != tuning { tuning = value }
            defaults.set(value.columns, forKey: "rain.columns")
            defaults.set(value.brightness, forKey: "rain.brightness")
            defaults.set(value.speed, forKey: "rain.speed")
            defaults.set(value.fade, forKey: "rain.fade")
            defaults.set(value.floatingClock, forKey: "clock.floating")
            defaults.set(value.clockTypeface.rawValue, forKey: "clock.typeface")
            defaults.set(value.clockSize, forKey: "clock.size")
        }
    }
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["rain.columns": 96, "rain.brightness": 0.18, "rain.speed": 0.43, "rain.fade": 3.0,
                                     "clock.floating": true, "clock.typeface": "system", "clock.size": 1.0])
        tuning = RainTuning(columns: defaults.integer(forKey: "rain.columns"),
                            brightness: defaults.double(forKey: "rain.brightness"),
                            speed: defaults.double(forKey: "rain.speed"),
                            fade: defaults.double(forKey: "rain.fade"),
                            floatingClock: defaults.bool(forKey: "clock.floating"),
                            clockTypeface: ClockTypeface(rawValue: defaults.string(forKey: "clock.typeface") ?? "") ?? .system,
                            clockSize: defaults.double(forKey: "clock.size")).normalized()
    }
}
