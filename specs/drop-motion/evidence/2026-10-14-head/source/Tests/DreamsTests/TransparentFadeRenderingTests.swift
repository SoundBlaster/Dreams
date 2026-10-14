import AppKit
import MetalKit
import Testing
@testable import Dreams

/// Real GPU coverage; run with an isolated feed so hooks cannot alter the fixture.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct TransparentFadeRenderingTests {
    @Test(arguments: [true, false], [true, false])
    func dissolvingGlyphRevealsTheBackgroundWithoutTurningBlack(restored: Bool, keyword: Bool) async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let feed = KeywordFeed()
        let session = "alpha-fade-\(UUID())"
        if keyword { try feed.publish(sessionID: session, words: ["MATRIX"], eventLabel: "MMMM") }
        defer { if keyword { try? feed.clear(sessionID: session) } }
        let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true, transparentBackground: true)
        try renderer.setRestoredGlyphs(restored)
        renderer.rainIdleIntensity = 1
        renderer.rainColumnCount = 48
        renderer.rainDensity = 0.5
        renderer.rainFadeRows = 16
        renderer.rainSpeed = 1
        // Isolate alpha fading from the independently configurable glyph search.
        renderer.rainSearchFraction = 0
        renderer.rainGlow = 0
        renderer.rainBrightnessSpread = 0
        renderer.rainTint = SIMD3(0.08, 0.35, 0.15)
        renderer.keywordTint = renderer.rainTint
        renderer.keywordBrightness = 1

        // Pick a busy column at idle. A wide fade starts immediately, before any mutation.
        var simulation = MatrixSimulation(columnCount: 48, rows: 31, glyphCount: 57,
                                          density: 0.5, fadeRows: 16)
        simulation.setSearchFraction(0)
        let coverage = RainActivity(idleIntensity: 1).coverage(at: 0, density: 0.5)
        if keyword { _ = simulation.trigger(column: 9, at: 0) }
        simulation.advance(to: 0, coverage: coverage)
        let column = keyword ? 9 : try #require(simulation.columns.indices.first { !simulation.columns[$0].resting })
        simulation.advance(to: simulation.columns[column].nextWrite, coverage: coverage)
        let cell = simulation.columns[column].cells[0]
        try #require(!cell.isGap)
        _ = try await renderer.previewPNG(posedTime: 0)
        let left = Int((Double(column) + 0.12) * 1512 / 48)
        let right = Int((Double(column) + 0.88) * 1512 / 48)
        var samples: [SIMD4<Double>] = []
        for (index, progress) in [0.2, 0.6, 0.95, 1.01].enumerated() {
            let time = Float(cell.writtenAt + cell.hold + progress * cell.fade)
            let png = try await renderer.previewPNG(posedTime: time)
            let image = try #require(NSBitmapImageRep(data: png))
            // Stay inside row zero, clear of the next row's overlapping quad.
            var total = SIMD4<Double>.zero
            for y in 0..<26 {
                for x in left..<right {
                    let color = try #require(image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB))
                    let alpha = color.alphaComponent
                    total += SIMD4(Double(color.redComponent * alpha), Double(color.greenComponent * alpha),
                                   Double(color.blueComponent * alpha), Double(alpha))
                }
            }
            samples.append(total)
            if let path = ProcessInfo.processInfo.environment["DREAMS_CAPTURE_ALPHA_DIR"] {
                let name = "\(keyword ? "event" : "rain")-\(restored ? "restored" : "classic")"
                let directory = URL(fileURLWithPath: path).appendingPathComponent(name)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try png.write(to: directory.appendingPathComponent("fade-\(index).png"))
                try "{\"left\":\(left),\"right\":\(right),\"bottom\":26}".write(
                    to: directory.appendingPathComponent("crop.json"), atomically: true, encoding: .utf8)
            }
        }
        try #require(samples[0].w > 1, "The crop must contain a visible glyph")
        #expect(abs(samples[1].w / samples[0].w - 0.5) < 0.03,
                "Halfway through the fade, coverage must halve rather than darken opaque ink")
        #expect(abs(samples[2].w / samples[0].w - 0.0625) < 0.02)
        #expect(samples[3].w == 0, "Expired ink must leave no dark silhouette")
        // Straight colour stays green while alpha falls; allow the live phosphor noise.
        let earlyGreen = samples[0].y / samples[0].w
        let lateGreen = samples[2].y / samples[2].w
        #expect(abs(lateGreen - earlyGreen) < 0.08)
    }
}
