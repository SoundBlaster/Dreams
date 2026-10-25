import MetalKit
import XCTest
@testable import DreamsTV

@MainActor
final class GlyphSpacingTests: XCTestCase {
    func testRestoredBodyFillsRowsWhileShortMarksKeepTheirNaturalSize() throws {
        let view = MTKView()
        let renderer = try MatrixRenderer(view: view) { XCTFail("Renderer failed") }
        defer { view.isPaused = true; view.delegate = nil }
        let atlas = try FilmAtlas(device: XCTUnwrap(view.device))
        var simulation = MatrixSimulation(columnCount: 24, rows: 16, glyphCount: atlas.variantCount, seed: 31, density: 1)
        simulation.advance(to: 10)
        var tuning = RainTuning(density: 1)
        tuning.showsClock = false
        let cells = renderer.makeCells(simulation: simulation, tuning: tuning, wallTime: 10)
        let quad = try XCTUnwrap(cells.cores.first).rect
        let fullBody = inkHeight(atlas: atlas, index: 20) // G21: body baseline0...cap780.
        let dash = inkHeight(atlas: atlas, index: 24) // G25: deliberately short.
        let coverage = Float(fullBody) / 28 * quad.w * 16
        XCTAssertGreaterThanOrEqual(coverage, 0.97, "Full-height film bodies should nearly touch adjacent rows")
        XCTAssertLessThan(coverage, 1.07, "Do not make the common body overlap whole rows")
        XCTAssertLessThan(Float(dash) / 28 * quad.w * 16, 0.25, "Do not fit punctuation independently")
        XCTAssertEqual(quad.z * 24 / (quad.w * 16), FPSGrid.glyphWidth / FPSGrid.glyphHeight, accuracy: 0.00001,
                       "Use one common factor on both axes, preserving the previous ink proportions")
        let fps = try XCTUnwrap(FPSGrid(columns: 24, rows: 16, glyphScale: atlas.glyphScale))
        XCTAssertEqual(fps.rect(column: 4).z, quad.z)
        XCTAssertEqual(fps.rect(column: 4).w, quad.w)
        print("Restored row coverage: \(coverage); short mark: \(Float(dash) / 28 * quad.w * 16); scale: \(atlas.glyphScale)")
    }

    func testClassicRepertoireKeepsItsExistingGeometry() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        let atlas = try FilmAtlas(device: device, restored: false)
        XCTAssertEqual(atlas.glyphScale, 1)
    }

    private func inkHeight(atlas: FilmAtlas, index: Int) -> Int {
        var pixels = [UInt8](repeating: 0, count: FilmAtlas.width * atlas.height)
        pixels.withUnsafeMutableBytes {
            atlas.core.getBytes($0.baseAddress!, bytesPerRow: FilmAtlas.width,
                                from: MTLRegionMake2D(0, 0, FilmAtlas.width, atlas.height), mipmapLevel: 0)
        }
        let occupied = (0..<64).filter { row in
            (0..<64).contains { column in
                pixels[(index / 8 * 64 + row) * FilmAtlas.width + index % 8 * 64 + column] > 32
            }
        }
        guard let first = occupied.first, let last = occupied.last else { return 0 }
        return last - first + 1
    }
}
