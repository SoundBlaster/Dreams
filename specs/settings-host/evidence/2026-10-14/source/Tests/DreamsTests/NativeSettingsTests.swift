import AppKit
import Observation
import os
import Testing
@testable import Dreams

@Suite(.serialized)
@MainActor
struct NativeSettingsTests {
    static let savedKeys = ["rainColumnCount", "rainDensity", "rainSpeed", "rainSearchFraction", "rainFadeRows",
                            "rainDecelerationEnabled", "rainDeceleration", "rainBrightnessSpread", "rainGlow", "transparentRainGlow",
                            "rainIdleIntensity", "rainColor", "transparentRainColor", "keywordColor", "keywordBrightness",
                            "transparentBackground", "restoredGlyphs", "hideFromScreenshots", "runTimeSeconds",
                            "rainDisplayMode", "rainDisplayIDs"]

    static func preserveDefaults() -> () -> Void {
        let defaults = UserDefaults.standard
        let values = savedKeys.map { defaults.object(forKey: $0) }
        return {
            for (key, value) in zip(savedKeys, values) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
    }

    @Test func launchFlagDefaultsOffAndExplicitLegacyWins() {
        #expect(!NativeSettingsFeature.isEnabled(arguments: ["Dreams"]))
        #expect(NativeSettingsFeature.isEnabled(arguments: ["Dreams", "--native-settings"]))
        #expect(!NativeSettingsFeature.isEnabled(arguments: ["Dreams", "--native-settings", "--legacy-settings"]))
    }

    @Test func nativeBindingsUseTheProductionOwnerAndRejectInvalidValues() throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller, nativeSettingsEnabled: true)
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        defer { page.cleanUp() }
        #expect(model.controller === controller)
        let keys: [NativeRainParameter: String] = [
            .density: "rainDensity", .speed: "rainSpeed", .search: "rainSearchFraction", .deceleration: "rainDeceleration",
            .fade: "rainFadeRows", .spread: "rainBrightnessSpread", .glow: controller.transparentBackground ? "transparentRainGlow" : "rainGlow",
            .idle: "rainIdleIntensity", .keywordBrightness: "keywordBrightness"
        ]
        for parameter in NativeRainParameter.allCases {
            for value in [parameter.range.lowerBound, parameter.range.upperBound] {
                model[parameter: parameter] = value
                #expect(controller[keyPath: parameter.keyPath] == value)
                #expect(UserDefaults.standard.double(forKey: try #require(keys[parameter])) == value)
            }
            let previous = model[parameter: parameter]
            model[parameter: parameter] = .nan
            #expect(model[parameter: parameter] == previous)
            model[parameter: parameter] = parameter.range.upperBound + 100
            #expect(model[parameter: parameter] == parameter.range.upperBound)
        }
        model[parameter: .fade] = 8.7
        #expect(controller.rainFadeRows == 9)
        model.automaticColumns = false
        model.columns = 91.4
        #expect(controller.rainColumnCount == 91)
        model.automaticColumns = true
        #expect(controller.rainColumnCount == 0)
        model.runTime = 300
        model.runTime = -99
        #expect(controller.runTimeSeconds == 300)
        let changed = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking { _ = model[parameter: .speed] } onChange: { changed.withLock { $0 = true } }
        controller.rainSpeed = 0.73
        #expect(changed.withLock { $0 })
        #expect(model[parameter: .speed] == 0.73)
    }

    @Test func bothWindowsSharePreferencesAndOneActivityTimer() throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let page = SettingsPageController(controller: DreamsController(), nativeSettingsEnabled: true)
        defer { page.controlsWindow?.close(); page.cleanUp() }
        page.showControls()
        let window = try #require(page.nativeWindow)
        let model = try #require(page.nativeModel)
        #expect(page.controlsWindow == nil)
        #expect(window.identifier?.rawValue == "dreams.native-settings")
        let timer = try #require(page.activityTimer)
        page.showLegacyControls()
        #expect(page.activityTimer === timer)
        model[parameter: .speed] = 0.43
        let speed = try #require(page.controlsByID["dreams.rain-speed"] as? NSSlider)
        #expect(speed.doubleValue == 0.43)
        speed.doubleValue = 0.91
        page.changeSpeed(speed)
        #expect(model[parameter: .speed] == 0.91)
        try page.controller.setTransparentBackground(false)
        model[parameter: .glow] = 0.63
        model.transparent = true
        model[parameter: .glow] = 0.12
        model.transparent = false
        #expect(model[parameter: .glow] == 0.63)
        model.transparent = true
        #expect(model[parameter: .glow] == 0.12)
        #expect((page.controlsByID["dreams.transparent-background"] as? NSButton)?.state == .on)
        window.close()
        page.showControls()
        #expect(page.nativeWindow === window)
        #expect(page.activityTimer === timer)
        page.cleanUp()
        #expect(!timer.isValid)
        #expect(page.nativeWindow == nil && page.nativeModel == nil)
    }
}
