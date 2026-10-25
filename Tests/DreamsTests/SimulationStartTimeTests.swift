import MetalKit
import Testing
@testable import Dreams

struct SimulationStartTimeTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_METAL"] == "1"))
    @MainActor func automaticGridAfterLongSessionDoesNotReplayTheSession() async throws {
        let renderer = try RainRenderer(view: MTKView(), restoredGlyphs: true)
        renderer.rainColumnCount = 24
        renderer.rainDensity = 1
        renderer.rainFadeRows = 3
        renderer.rainSpeed = 0.43
        renderer.rainSearchFraction = 0.2
        renderer.rainIdleIntensity = 1
        renderer.rainDeceleration = .init(enabled: true, acceleration: -37.5)
        let pixels = SIMD2<Int>(128, 128)
        let screen = CGSize(width: 1512, height: 982)
        _ = try await renderer.previewPNG(posedTime: 0, pixelSize: pixels, referenceSize: screen)
        renderer.rainColumnCount = 0
        let frame = RainFrameMeasurement()
        let image = try await renderer.previewPNG(posedTime: 9 * 3600, pixelSize: pixels,
                                                 referenceSize: screen, measurement: frame)
        #expect(!image.isEmpty)
        // A generous guard for this isolated CPU stage, not a full UI/GPU performance budget.
        #expect(frame.simulationSeconds > 0 && frame.simulationSeconds < 1)
    }

    @Test(arguments: [9 * 3600.0, 7 * 24 * 3600.0])
    func aFreshGridAtALateClockMatchesANewSession(start: Double) throws {
        let motion = MatrixSimulation.Deceleration(enabled: true, acceleration: -37.5)
        var fresh = MatrixSimulation(columnCount: 12, rows: 72, glyphCount: 87,
                                     density: 1, fadeRows: 3, deceleration: motion)
        var late = MatrixSimulation(columnCount: 12, rows: 72, glyphCount: 87,
                                    density: 1, fadeRows: 3, deceleration: motion, startTime: start)
        // Fail before advancing if a regression would replay hours of historical events.
        try #require(late.time == start)
        try #require(late.columns.allSatisfy { $0.nextWrite >= start })
        fresh.setSearchFraction(0.2)
        late.setSearchFraction(0.2)
        for elapsed in [0.0, 0.17, 0.83, 2.31, 6.0] {
            fresh.advance(to: elapsed)
            late.advance(to: start + elapsed)
            #expect(late.visibleSymbolCount == fresh.visibleSymbolCount)
            #expect(late.searchingSymbolCount == fresh.searchingSymbolCount)
            for index in fresh.columns.indices {
                #expect(late.columns[index].headRow == fresh.columns[index].headRow)
                for row in 0..<fresh.rows {
                    let expected = fresh.columns[index].cells[row]
                    let actual = late.columns[index].cells[row]
                    #expect(actual.glyph == expected.glyph && actual.isGap == expected.isGap)
                    if expected.writtenAt.isFinite {
                        #expect(abs((actual.writtenAt - start) - expected.writtenAt) < 0.00001)
                    }
                    #expect(abs(late.opacity(column: index, row: row) - fresh.opacity(column: index, row: row)) < 0.00001)
                }
            }
        }
        #expect(late.visibleSymbolCount > 0)
    }

    @Test func zeroStartKeepsExistingTimingAndInvalidStartsAreNormalized() {
        for start in [0, -1, Double.nan, .infinity] {
            let rain = MatrixSimulation(columnCount: 12, rows: 72, glyphCount: 87, startTime: start)
            #expect(rain.time == 0)
            #expect(rain.columns.allSatisfy { (0...2.8).contains($0.nextWrite) })
        }
    }
}
