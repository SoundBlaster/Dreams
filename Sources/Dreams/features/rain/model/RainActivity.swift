import Foundation

/// Rain coverage driven by agent messages: every new message floods the screen, which then
/// falls back to the calm background set by the idle slider.
///
///   message → rise to full coverage (attack) → hold → exponential fall to calm (decay)
///
/// A message during the fall floods again from the current level, so a busy agent keeps
/// the rain dense and a quiet one lets it settle.
struct RainActivity {
    static let idleLevel: Float = 0.09
    static let attack = 0.4      // seconds to reach full coverage
    static let hold = 1.5        // seconds at full coverage
    static let decay = 5.0       // time constant of the fall back to calm

    private var idle: Float = idleLevel
    private var surgeFrom: Float = idleLevel
    private var surgeAt = -Double.infinity

    init(idleIntensity: Double = 0.2) {
        idle = Self.levelForIdle(idleIntensity)
        surgeFrom = idle
    }

    private static func levelForIdle(_ value: Double) -> Float {
        Float(value.isFinite ? min(1, max(0, value)) : 0.2) * 0.45
    }

    /// The calm level follows the idle slider live.
    mutating func update(at time: Double, idleIntensity: Double = 0.2) {
        idle = Self.levelForIdle(idleIntensity)
    }

    /// A new agent message: flood again, starting from wherever the rain is now.
    mutating func surge(at time: Double) {
        surgeFrom = level(at: time)
        surgeAt = time
    }

    func level(at time: Double) -> Float {
        let dt = time - surgeAt
        guard dt.isFinite, dt >= 0 else { return idle }
        if dt < Self.attack {
            let t = Float(dt / Self.attack)
            return surgeFrom + (1 - surgeFrom) * t * t * (3 - 2 * t)
        }
        let falling = dt - Self.attack - Self.hold
        guard falling > 0 else { return 1 }
        return idle + (1 - idle) * Float(exp(-falling / Self.decay))
    }

    /// 0 at calm, 1 from half coverage up: drives exposure and the density fill.
    func workBlend(at time: Double) -> Float {
        min(1, max(0, (level(at: time) - idle) / max(0.001, 0.5 - idle)))
    }

    /// Share of columns that rain: the activity level, lifted towards everything by the density
    /// slider (100% fills every column, calm or not). Which columns is re-drawn on every pass.
    func coverage(at time: Double, density: Double = 0) -> Double {
        let level = Double(level(at: time))
        let d = density.isFinite ? min(1, max(0, density)) : 0
        return level + (1 - level) * d * d * d
    }
}
