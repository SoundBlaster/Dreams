import Darwin
import Foundation
import Observation

/// First supported Apple TV (A8): owner measured 11–12 FPS with glow and 25 FPS without it.
enum TVHardwareDefaults {
    static var machineIdentifier: String {
        var info = utsname()
        guard uname(&info) == 0 else { return "" }
        return withUnsafeBytes(of: &info.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }

    static func glow(machine: String) -> Double { machine == "AppleTV5,3" ? 0 : DreamsPreset.glow }
}

enum ClockTypeface: String, CaseIterable {
    case system, rounded, monospaced
    var titleKey: String { "settings.font.\(rawValue)" }
}

/// Stored sRGB components; shading uses the same linear-light conversion as macOS.
struct RainColor: Equatable {
    var red = DreamsPreset.rainColor[0]
    var green = DreamsPreset.rainColor[1]
    var blue = DreamsPreset.rainColor[2]

    var linear: SIMD3<Float> {
        func channel(_ value: Double) -> Float {
            Float(value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4))
        }
        return SIMD3(channel(red), channel(green), channel(blue))
    }
}

struct RainTuning: Equatable {
    static let columnRange = 24...240
    static let densityRange = 0.0...1.0
    static let brightnessRange = 0.02...0.35
    static let speedRange = 0.25...3.0
    static let fadeRange = 1.0...16.0
    static let clockSizeRange = 0.5...1.15

    // Preserve existing TV preferences/defaults; new controls use the macOS preset.
    var columns = 96
    var density = 0.82
    var brightness = 0.18
    var speed = 0.43
    var fade = 3.0
    var floatingClock = true
    var clockTypeface = ClockTypeface.system
    var clockSize = 1.0
    var automaticColumns = false
    var searchFraction = DreamsPreset.searchFraction
    var decelerationEnabled = DreamsPreset.decelerationEnabled
    var acceleration = DreamsPreset.deceleration
    var brightnessSpread = DreamsPreset.brightnessSpread
    var pulseStrength = DreamsPreset.pulseStrength
    var glow = DreamsPreset.glow
    var color = RainColor()
    var restoredGlyphs = true
    var showsClock = true
    var showsFPS = false

    var deceleration: MatrixSimulation.Deceleration {
        MatrixSimulation.Deceleration(enabled: decelerationEnabled, acceleration: acceleration)
    }

    func grid(aspect: Double) -> (columns: Int, rows: Int) {
        let aspect = aspect.isFinite ? min(10, max(0.1, aspect)) : 16.0 / 9
        return automaticColumns
            ? (max(24, Int(aspect * 72)), 72)
            : (columns, max(8, Int((Double(columns) / aspect).rounded())))
    }

    /// TV's clock keeps a dim occupied tail at full density; never revive empty cells.
    func glyphOpacity(_ opacity: Float) -> Float {
        opacity > 0 && density >= 1 ? max(0.2, opacity) : opacity
    }

    func normalized() -> Self {
        var result = self
        result.columns = min(Self.columnRange.upperBound, max(Self.columnRange.lowerBound, columns))
        result.density = Self.clamp(density, to: Self.densityRange, fallback: 0.82)
        result.brightness = Self.clamp(brightness, to: Self.brightnessRange, fallback: 0.18)
        result.speed = Self.clamp(speed, to: Self.speedRange, fallback: 0.43)
        result.fade = Self.clamp(fade, to: Self.fadeRange, fallback: 3)
        result.clockSize = Self.clamp(clockSize, to: Self.clockSizeRange, fallback: 1)
        result.searchFraction = Self.clamp(searchFraction, to: 0...1, fallback: DreamsPreset.searchFraction)
        result.acceleration = Self.clamp(acceleration, to: MatrixSimulation.Deceleration.minimumAcceleration...0,
                                         fallback: DreamsPreset.deceleration)
        result.brightnessSpread = Self.clamp(brightnessSpread, to: 0...1, fallback: DreamsPreset.brightnessSpread)
        result.pulseStrength = Self.clamp(pulseStrength, to: 0...1, fallback: DreamsPreset.pulseStrength)
        result.glow = Self.clamp(glow, to: 0...3, fallback: DreamsPreset.glow)
        result.color.red = Self.clamp(color.red, to: 0...1, fallback: DreamsPreset.rainColor[0])
        result.color.green = Self.clamp(color.green, to: 0...1, fallback: DreamsPreset.rainColor[1])
        result.color.blue = Self.clamp(color.blue, to: 0...1, fallback: DreamsPreset.rainColor[2])
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
            defaults.set(value.density, forKey: "rain.density")
            defaults.set(value.brightness, forKey: "rain.brightness")
            defaults.set(value.speed, forKey: "rain.speed")
            defaults.set(value.fade, forKey: "rain.fade")
            defaults.set(value.floatingClock, forKey: "clock.floating")
            defaults.set(value.clockTypeface.rawValue, forKey: "clock.typeface")
            defaults.set(value.clockSize, forKey: "clock.size")
            defaults.set(value.automaticColumns, forKey: "rain.automaticColumns")
            defaults.set(value.searchFraction, forKey: "rain.searchFraction")
            defaults.set(value.decelerationEnabled, forKey: "rain.decelerationEnabled")
            defaults.set(value.acceleration, forKey: "rain.acceleration")
            defaults.set(value.brightnessSpread, forKey: "rain.brightnessSpread")
            defaults.set(value.pulseStrength, forKey: "rain.pulseStrength")
            defaults.set(value.glow, forKey: "rain.glow")
            defaults.set([value.color.red, value.color.green, value.color.blue], forKey: "rain.color")
            defaults.set(value.restoredGlyphs, forKey: "rain.restoredGlyphs")
            defaults.set(value.showsClock, forKey: "clock.visible")
            defaults.set(value.showsFPS, forKey: "debug.showsFPS")
        }
    }
    private let defaults: UserDefaults
    private let defaultTuning: RainTuning

    func reset() { tuning = defaultTuning }

    init(defaults: UserDefaults = .standard, machine: String = TVHardwareDefaults.machineIdentifier) {
        self.defaults = defaults
        var initial = RainTuning()
        initial.glow = TVHardwareDefaults.glow(machine: machine)
        defaultTuning = initial
        defaults.register(defaults: ["rain.columns": 96, "rain.density": 0.82, "rain.brightness": 0.18, "rain.speed": 0.43, "rain.fade": 3.0,
                                     "clock.floating": true, "clock.typeface": "system", "clock.size": 1.0,
                                     "rain.automaticColumns": false, "rain.searchFraction": DreamsPreset.searchFraction,
                                     "rain.decelerationEnabled": DreamsPreset.decelerationEnabled, "rain.acceleration": DreamsPreset.deceleration,
                                     "rain.brightnessSpread": DreamsPreset.brightnessSpread, "rain.pulseStrength": DreamsPreset.pulseStrength,
                                     "rain.glow": initial.glow, "rain.color": DreamsPreset.rainColor,
                                     "rain.restoredGlyphs": true, "clock.visible": true])
        let components = defaults.array(forKey: "rain.color") as? [Double] ?? DreamsPreset.rainColor
        let color = components.count == 3
            ? RainColor(red: components[0], green: components[1], blue: components[2]) : RainColor()
        tuning = RainTuning(columns: defaults.integer(forKey: "rain.columns"), density: defaults.double(forKey: "rain.density"),
                            brightness: defaults.double(forKey: "rain.brightness"), speed: defaults.double(forKey: "rain.speed"),
                            fade: defaults.double(forKey: "rain.fade"), floatingClock: defaults.bool(forKey: "clock.floating"),
                            clockTypeface: ClockTypeface(rawValue: defaults.string(forKey: "clock.typeface") ?? "") ?? .system,
                            clockSize: defaults.double(forKey: "clock.size"), automaticColumns: defaults.bool(forKey: "rain.automaticColumns"),
                            searchFraction: defaults.double(forKey: "rain.searchFraction"),
                            decelerationEnabled: defaults.bool(forKey: "rain.decelerationEnabled"), acceleration: defaults.double(forKey: "rain.acceleration"),
                            brightnessSpread: defaults.double(forKey: "rain.brightnessSpread"), pulseStrength: defaults.double(forKey: "rain.pulseStrength"),
                            glow: defaults.double(forKey: "rain.glow"), color: color,
                            restoredGlyphs: defaults.bool(forKey: "rain.restoredGlyphs"), showsClock: defaults.bool(forKey: "clock.visible"),
                            showsFPS: defaults.bool(forKey: "debug.showsFPS")).normalized()
    }
}
