import XCTest
import MetalKit
@testable import DreamsTV

@MainActor
final class DreamsTVTests: XCTestCase {
    func testSettingsStringsAreBundledInBothLanguages() throws {
        for language in ["en", "ru"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in ["settings.columns", "settings.brightness", "settings.speed", "settings.fade", "settings.done",
                        "settings.floating", "settings.typeface", "settings.size", "settings.font.rounded"] {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: nil, table: nil), key)
            }
        }
    }

    func testBundledFontAndClockShaderLoadOnGPU() throws {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let renderer = try MatrixRenderer(view: view) { XCTFail("Renderer failed") }
        XCTAssertNotNil(view.device)
        XCTAssertNotNil(view.delegate)
        withExtendedLifetime(renderer) { view.isPaused = true }
        view.delegate = nil
    }

    func testInvalidSettingsAreNormalizedAndPersisted() {
        let name = "DreamsTVTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = RainSettings(defaults: defaults)
        settings.tuning = RainTuning(columns: 999, brightness: .nan, speed: -1, fade: .infinity)
        XCTAssertEqual(settings.tuning, RainTuning(columns: 160, brightness: 0.18, speed: 0.25, fade: 3))
        XCTAssertEqual(RainSettings(defaults: defaults).tuning, settings.tuning)
    }

    func testClockAppearancePersistsAndSizeIsBounded() {
        let name = "DreamsTVTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = RainSettings(defaults: defaults)
        settings.tuning.floatingClock = false
        settings.tuning.clockTypeface = .rounded
        settings.tuning.clockSize = 9
        let restored = RainSettings(defaults: defaults).tuning
        XCTAssertFalse(restored.floatingClock)
        XCTAssertEqual(restored.clockTypeface, .rounded)
        XCTAssertEqual(restored.clockSize, 1.15)
    }

    func testEveryClockFontFitsAtMaximumSizeAndHasDistinctShape() throws {
        var masks: [[UInt8]] = []
        for font in ClockTypeface.allCases {
            let mask = try ClockMask(time: "23:59", aspect: 16.0 / 9, typeface: font, size: 1.15)
            XCTAssertLessThan(mask.occupiedWidth, 0.94)
            XCTAssertLessThan(mask.occupiedHeight, 0.94)
            XCTAssertTrue(mask.pixels.prefix(mask.width * 16).allSatisfy { $0 == 0 })
            XCTAssertTrue(mask.pixels.suffix(mask.width * 16).allSatisfy { $0 == 0 })
            masks.append(mask.pixels)
        }
        XCTAssertNotEqual(masks[0], masks[1])
        XCTAssertNotEqual(masks[0], masks[2])
    }

    func testRepertoireHasOnlyFilmGlyphsAndHorizontalMirrors() {
        XCTAssertEqual(FilmGlyphs.scalars.count, 28)
        XCTAssertTrue(FilmGlyphs.scalars.allSatisfy { (0xE001...0xE01C).contains(Int($0.value)) })
        for variant in 0..<28 {
            let normal = FilmGlyphs.uv(for: variant, inset: 18, side: 28, atlasWidth: 512, atlasHeight: 256)
            let mirrored = FilmGlyphs.uv(for: variant + 28, inset: 18, side: 28, atlasWidth: 512, atlasHeight: 256)
            XCTAssertEqual(normal.x + normal.z, mirrored.x, accuracy: 0.0001)
            XCTAssertEqual(normal.y, mirrored.y)
            XCTAssertEqual(normal.z, -mirrored.z)
            XCTAssertEqual(normal.w, mirrored.w)
        }
    }

    func testClockMaskContainsOnlyDigitSilhouettes() throws {
        let early = try ClockMask(time: "12:34", aspect: 16.0 / 9)
        let later = try ClockMask(time: "12:35", aspect: 16.0 / 9)
        let lit = early.pixels.filter { $0 > 127 }.count
        XCTAssertGreaterThan(lit, early.pixels.count / 20)
        XCTAssertLessThan(lit, early.pixels.count / 3)
        XCTAssertNotEqual(early.pixels, later.pixels)
        XCTAssertTrue(early.pixels.prefix(early.width * 20).allSatisfy { $0 == 0 })
        XCTAssertTrue(early.pixels.suffix(early.width * 20).allSatisfy { $0 == 0 })
    }

    func testClockSelectsWholeGlyphCellsAndLeavesOutsideDark() throws {
        let mask = try ClockMask(time: "08:58", aspect: 16.0 / 9)
        let illuminated = (0..<54).flatMap { row in
            (0..<96).map { column in
                mask.illuminates(center: SIMD2((Float(column) + 0.5) / 96, (Float(row) + 0.5) / 54))
            }
        }.filter { $0 }.count
        XCTAssertGreaterThan(illuminated, 200)
        XCTAssertLessThan(illuminated, 96 * 54 / 3)
        XCTAssertFalse(mask.illuminates(center: SIMD2(-0.1, 0.5)))
        XCTAssertFalse(mask.illuminates(center: SIMD2(1, 0.5)))
        XCTAssertFalse(mask.illuminates(center: SIMD2(.nan, 0.5)))
    }

    func testClockMinuteDoesNotChangeWithinMinute() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let start = Calendar.current.dateInterval(of: .minute, for: date)!.start
        XCTAssertEqual(ClockMask.minuteKey(at: start), ClockMask.minuteKey(at: start.addingTimeInterval(59)))
        XCTAssertNotEqual(ClockMask.minuteKey(at: start), ClockMask.minuteKey(at: start.addingTimeInterval(60)))
    }
}
