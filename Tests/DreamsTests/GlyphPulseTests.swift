import Foundation
import Testing
@testable import Dreams

struct GlyphPulseTests {
    @Test func disabledAndInvalidInputsKeepExistingExposure() {
        for time in [0.0, 0.3, 100, .greatestFiniteMagnitude] {
            #expect(GlyphPulse.gain(at: time, column: 4, row: 7, strength: 0) == 1)
        }
        #expect(GlyphPulse.gain(at: .nan, column: 0, row: 0, strength: 1) == 1)
        #expect(GlyphPulse.gain(at: 1, column: 0, row: 0, strength: .infinity) == 1)
    }

    @Test func independentSmoothPhasesHaveABoundedNonzeroFloor() {
        var a: [Float] = [], b: [Float] = []
        for frame in 0...600 {
            let time = Double(frame) / 60
            a.append(GlyphPulse.gain(at: time, column: 4, row: 7, strength: 1))
            b.append(GlyphPulse.gain(at: time, column: 4, row: 8, strength: 1))
        }
        #expect(a != b)
        #expect(a.max()! - a.min()! > 1)
        #expect(a.allSatisfy { $0 >= 0.3499 && $0 <= 1.6501 })
        #expect(zip(a, a.dropFirst()).allSatisfy { abs($0 - $1) < 0.06 })
        #expect(GlyphPulse.gain(at: .greatestFiniteMagnitude, column: 4, row: 7, strength: 1).isFinite)
        #expect(GlyphPulse.gain(at: 3, column: 4, row: 7, strength: 2)
            == GlyphPulse.gain(at: 3, column: 4, row: 7, strength: 1))
    }

    @Test func strengthScalesTheEnvelopeWithoutChangingItsPhase() {
        for time in [0.2, 0.8, 1.7, 4.5] {
            let full = GlyphPulse.gain(at: time, column: 4, row: 7, strength: 1)
            let half = GlyphPulse.gain(at: time, column: 4, row: 7, strength: 0.5)
            #expect(abs((half - 1) - (full - 1) * 0.5) < 0.00001)
        }
    }
}
