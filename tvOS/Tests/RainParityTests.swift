import CoreText
import MetalKit
import XCTest
@testable import DreamsTV

@MainActor
final class RainParityTests: XCTestCase {
    func testNewOptionsMigrateExistingPreferencesAndPersist() throws {
        let name = "DreamsTVParityTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(120, forKey: "rain.columns")
        defaults.set(0.65, forKey: "rain.density")
        defaults.set(0.12, forKey: "rain.brightness")
        let settings = RainSettings(defaults: defaults)
        XCTAssertEqual(settings.tuning.columns, 120)
        XCTAssertEqual(settings.tuning.density, 0.65)
        XCTAssertEqual(settings.tuning.brightness, 0.12)
        XCTAssertEqual(settings.tuning.pulseStrength, DreamsPreset.pulseStrength)
        XCTAssertTrue(settings.tuning.showsClock)
        XCTAssertFalse(settings.tuning.showsFPS)
        settings.tuning.automaticColumns = true
        settings.tuning.searchFraction = 0.73
        settings.tuning.decelerationEnabled = true
        settings.tuning.acceleration = -40
        settings.tuning.brightnessSpread = 0.15
        settings.tuning.pulseStrength = 0.8
        settings.tuning.glow = 2.5
        settings.tuning.color = RainColor(red: 0.7, green: 0.2, blue: 0.9)
        settings.tuning.restoredGlyphs = false
        settings.tuning.showsClock = false
        settings.tuning.showsFPS = true
        XCTAssertEqual(RainSettings(defaults: defaults).tuning, settings.tuning)
        settings.reset()
        XCTAssertEqual(RainSettings(defaults: defaults).tuning, RainTuning())
    }

    func testBoundsInvalidValuesAndAutomaticGridMatchDesktop() {
        var tuning = RainTuning()
        tuning.columns = 999
        tuning.density = -1
        tuning.searchFraction = 9
        tuning.acceleration = -.infinity
        tuning.pulseStrength = .nan
        tuning.brightnessSpread = -1
        tuning.glow = 99
        tuning.color = RainColor(red: .nan, green: -1, blue: 99)
        tuning = tuning.normalized()
        XCTAssertEqual(tuning.columns, 240)
        XCTAssertEqual(tuning.density, 0)
        XCTAssertEqual(tuning.searchFraction, 1)
        XCTAssertEqual(tuning.acceleration, DreamsPreset.deceleration)
        XCTAssertEqual(tuning.pulseStrength, DreamsPreset.pulseStrength)
        XCTAssertEqual(tuning.brightnessSpread, 0)
        XCTAssertEqual(tuning.glow, 3)
        XCTAssertEqual(tuning.color.red, DreamsPreset.rainColor[0])
        XCTAssertEqual(tuning.color.green, 0)
        XCTAssertEqual(tuning.color.blue, 1)
        tuning.automaticColumns = true
        XCTAssertEqual(tuning.grid(aspect: 16.0 / 9).columns, 128)
        XCTAssertEqual(tuning.grid(aspect: 16.0 / 9).rows, 72)
        tuning.automaticColumns = false
        XCTAssertEqual(tuning.grid(aspect: 16.0 / 9).rows, 135)
        XCTAssertEqual(RainTuning(density: 1).glyphOpacity(0), 0)
    }

    func testRainColorUsesLinearLightRatherThanStoredSRGB() {
        let color = RainColor(red: 0.086, green: 0.547, blue: 0.26).linear
        XCTAssertEqual(color.x, 0.008, accuracy: 0.0001)
        XCTAssertEqual(color.y, 0.26, accuracy: 0.0002)
        XCTAssertEqual(color.z, 0.055, accuracy: 0.0001)
    }

    func testRendererKeepsGapHeadsBrightAndUsesRapidHeadGlyph() throws {
        let view = MTKView()
        let renderer = try MatrixRenderer(view: view) { XCTFail("Renderer failed") }
        defer { view.isPaused = true; view.delegate = nil }
        let atlas = try FilmAtlas(device: XCTUnwrap(view.device))
        var simulation = MatrixSimulation(columnCount: 24, rows: 16, glyphCount: atlas.variantCount, seed: 17, density: 0.1)
        simulation.setSearchFraction(0)
        simulation.setDeceleration(.init(enabled: true, acceleration: -120))
        var tuning = RainTuning()
        tuning.showsClock = false
        tuning.color = RainColor(red: 0, green: 0, blue: 0)
        tuning.glow = 0
        var witnessedGap = false
        var witnessedCycling = false
        for step in 1...300 {
            simulation.advance(to: Double(step) / 30)
            let cells = renderer.makeCells(simulation: simulation, tuning: tuning, wallTime: Double(step) / 30)
            XCTAssertTrue(cells.halos.isEmpty)
            for column in simulation.columns.indices {
                let row = simulation.columns[column].headRow
                guard row >= 0, simulation.headIntensity(column: column, row: row) > 0.9 else { continue }
                let symbol = simulation.columns[column].cells[row]
                let width: Float = 1.30 * (22.0 / 30.0) / (38.0 / 46.0)
                let x = (Float(column) + (1 - width) / 2) / 24
                let y = (Float(row) - 0.16) / 16
                let cell = try XCTUnwrap(cells.cores.first { abs($0.rect.x - x) < 0.00001 && abs($0.rect.y - y) < 0.00001 })
                let head = simulation.headIntensity(column: column, row: row)
                XCTAssertEqual(cell.color.x, 0.86 * head, accuracy: 0.0001)
                let glyph = simulation.headGlyph(column: column, row: row)
                let uv = FilmGlyphs.uv(for: glyph, inset: 18, side: 28, atlasWidth: 512,
                                      atlasHeight: Float(atlas.height), glyphCount: atlas.glyphCount)
                XCTAssertEqual(cell.uv, uv)
                witnessedGap = witnessedGap || symbol.isGap
                witnessedCycling = witnessedCycling || glyph != symbol.glyph
            }
        }
        XCTAssertTrue(witnessedGap, "Fixture must exercise a gap at the writing head")
        XCTAssertTrue(witnessedCycling, "Heads must cycle even when trail search is zero")
    }

    func testRendererPulseChangesInkWithoutChangingOccupancyAndGlowCanBeDisabled() throws {
        let view = MTKView()
        let renderer = try MatrixRenderer(view: view) { XCTFail("Renderer failed") }
        defer { view.isPaused = true; view.delegate = nil }
        let atlas = try FilmAtlas(device: XCTUnwrap(view.device))
        var rain = MatrixSimulation(columnCount: 24, rows: 16, glyphCount: atlas.variantCount, seed: 19, density: 1)
        rain.advance(to: 10)
        var tuning = RainTuning(density: 1)
        tuning.showsClock = false
        tuning.pulseStrength = 1
        let first = renderer.makeCells(simulation: rain, tuning: tuning, wallTime: 1)
        let second = renderer.makeCells(simulation: rain, tuning: tuning, wallTime: 2)
        XCTAssertEqual(first.cores.map(\.rect), second.cores.map(\.rect))
        XCTAssertEqual(first.cores.map(\.uv), second.cores.map(\.uv))
        XCTAssertNotEqual(first.cores.map(\.color), second.cores.map(\.color))
        XCTAssertFalse(first.halos.isEmpty)
        tuning.pulseStrength = 0
        tuning.glow = 0
        let stable = renderer.makeCells(simulation: rain, tuning: tuning, wallTime: 1)
        let later = renderer.makeCells(simulation: rain, tuning: tuning, wallTime: 2)
        XCTAssertEqual(stable.cores.map(\.color), later.cores.map(\.color))
        XCTAssertTrue(stable.halos.isEmpty)
    }
}
