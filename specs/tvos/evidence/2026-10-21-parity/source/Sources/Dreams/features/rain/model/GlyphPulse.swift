import Foundation

/// Whole-glyph exposure on real time; independent of typing, search and alpha lifetime.
enum GlyphPulse {
    static func gain(at time: Double, column: Int, row: Int, strength: Double) -> Float {
        guard time.isFinite, strength.isFinite else { return 1 }
        let amount = min(1, max(0, strength))
        guard amount > 0 else { return 1 }
        var seed = UInt32(truncatingIfNeeded: column) &* 1597334677
            ^ UInt32(truncatingIfNeeded: row) &* 3812015801
        seed ^= seed >> 16
        seed &*= 0x7feb352d
        seed ^= seed >> 15
        seed &*= 0x846ca68b
        seed ^= seed >> 16
        let period = 1 / (0.25 + 0.5 * Double(seed >> 16) / 65536)
        let phase = Double(seed & 0xffff) / 65536
        // Reduce before multiplying so even a very large finite clock stays finite.
        let wave = sin(2 * .pi * (time.truncatingRemainder(dividingBy: period) / period + phase))
        // A nonzero floor preserves live ink; only its existing lifecycle can erase it.
        return Float(1 + 0.65 * amount * wave)
    }
}
