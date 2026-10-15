import AppKit
import MetalKit
import Testing
@testable import Dreams

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct GlyphPulseRenderingTests {
    @Test(arguments: [false, true])
    func wholeGlyphExposurePulsesWithoutChangingItsCoverage(transparent: Bool) async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let times = (6...24).map { Float($0) / 10 }
        let ordered = times.sorted {
            GlyphPulse.gain(at: Double($0), column: 16, row: 0, strength: 1)
                < GlyphPulse.gain(at: Double($1), column: 16, row: 0, strength: 1)
        }
        var ratios: [Double] = []
        for (index, time) in [ordered.first!, ordered.last!].enumerated() {
            var samples: [SIMD2<Double>] = []
            for strength in [0.0, 1.0] {
                let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true,
                                                transparentBackground: transparent)
                renderer.rainIdleIntensity = 1
                renderer.rainColumnCount = 48
                renderer.rainDensity = 1
                renderer.rainGlow = 0
                renderer.rainSpeed = 0.25
                renderer.rainSearchFraction = 0
                renderer.rainBrightnessSpread = 0
                renderer.rainPulseStrength = strength
                _ = try await renderer.previewPNG(posedTime: 0)
                let png = try await renderer.previewPNG(posedTime: time)
                let image = try #require(NSBitmapImageRep(data: png))
                var sample = SIMD2<Double>.zero
                for y in 5..<25 {
                    for x in 512..<527 {
                        let c = try #require(image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB))
                        sample += SIMD2(Double(c.greenComponent * c.alphaComponent), Double(c.alphaComponent))
                    }
                }
                samples.append(sample)
                if let path = ProcessInfo.processInfo.environment["DREAMS_CAPTURE_PULSE_DIR"] {
                    let dir = URL(fileURLWithPath: path)
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    let name = "\(transparent ? "transparent" : "opaque")-\(index)-\(strength == 0 ? "off" : "on").png"
                    try png.write(to: dir.appendingPathComponent(name))
                }
            }
            try #require(samples[0].x > 0.1, "The crop must contain a live glyph")
            #expect(abs(samples[0].y - samples[1].y) < 0.001,
                    "Pulse changes colour exposure, never glyph coverage or alpha lifetime")
            ratios.append(samples[1].x / samples[0].x)
        }
        #expect(ratios[1] - ratios[0] > 0.1, "The whole glyph must visibly breathe beyond phosphor grain")
    }
}
