import AppKit
import MetalKit
import Testing
@testable import Dreams

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
@MainActor
struct DropHeadRenderingTests {
    @Test(arguments: [false, true], [false, true])
    func aLowInkHeadStaysPaleOnBothBackgrounds(transparent: Bool, braking: Bool) async throws {
        try await checkHead(transparent: transparent, braking: braking, gap: false)
    }

    @Test(arguments: [false, true])
    func aTrailGapCannotHideTheDrop(transparent: Bool) async throws {
        try await checkHead(transparent: transparent, braking: false, gap: true)
    }

    private func checkHead(transparent: Bool, braking: Bool, gap: Bool) async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let density = gap ? 0.0 : 1.0
        let coverage = RainActivity(idleIntensity: 1).coverage(at: 0, density: density)
        var rain = MatrixSimulation(columnCount: 48, rows: 31, glyphCount: 57, density: density,
                                    deceleration: .init(enabled: braking, acceleration: -120))
        rain.setSearchFraction(0)
        let initialStarts = rain.columns.map(\.nextWrite)
        var selected: Int?
        for frame in 0...600 {
            rain.advance(to: Double(frame) / 120, coverage: coverage)
            selected = rain.columns.indices.first { index in
                let c = rain.columns[index]
                guard c.headRow >= 10, c.headRow < 29, !c.resting,
                      c.packetStartedAt == initialStarts[index] else { return false }
                let cell = c.cells[c.headRow]
                return cell.ink < 0.4 && cell.isGap == gap
                    && c.lastWrite + (c.nextWrite - c.lastWrite) * 0.85 >= rain.time
            }
            if selected != nil { break }
        }
        let column = try #require(selected, "Fixture needs a dim head in an active first pass")
        let head = rain.columns[column]
        let time = Float(head.lastWrite + (head.nextWrite - head.lastWrite) * 0.85)
        let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true,
                                        transparentBackground: transparent)
        renderer.rainIdleIntensity = 1
        renderer.rainColumnCount = 48
        renderer.rainDensity = density
        renderer.rainGlow = 0
        renderer.rainSpeed = 1
        renderer.rainSearchFraction = 0
        renderer.rainDeceleration = .init(enabled: braking, acceleration: -120)
        renderer.brightness = 0.18
        _ = try await renderer.previewPNG(posedTime: 0)
        let png = try await renderer.previewPNG(posedTime: time)
        let image = try #require(NSBitmapImageRep(data: png))
        var whitePixels = 0
        for y in Int(Double(head.headRow) * 982 / 31)..<Int(Double(head.headRow + 1) * 982 / 31) {
            for x in Int(Double(column) * 1512 / 48)..<Int(Double(column + 1) * 1512 / 48) {
                let c = try #require(image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB))
                if c.alphaComponent > 0.5 && c.redComponent > 0.5
                    && c.redComponent / max(0.001, c.greenComponent) > 0.9 { whitePixels += 1 }
            }
        }
        #expect(whitePixels > 5, "A live head must have pale ink even without glow or high random ink")
        if let path = ProcessInfo.processInfo.environment["DREAMS_CAPTURE_HEAD_DIR"] {
            let url = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let name = "\(transparent ? "transparent" : "opaque")-\(braking ? "braking" : "constant")-\(gap ? "gap" : "ink")"
            try png.write(to: url.appendingPathComponent(name + ".png"))
        }
    }
}
