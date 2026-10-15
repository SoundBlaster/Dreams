import AppKit
import Testing
@testable import Dreams

@Suite(.serialized)
@MainActor
struct GlyphPulseSettingsTests {
    @Test func legacyPulseSliderPersistsAndSynchronizesWithNativeBindings() throws {
        _ = NSApplication.shared
        let restore = NativeSettingsTests.preserveDefaults()
        defer { restore() }
        UserDefaults.standard.removeObject(forKey: "rainPulseStrength")
        let controller = DreamsController()
        #expect(controller.rainPulseStrength == DreamsPreset.pulseStrength)
        let page = SettingsPageController(controller: controller)
        page.showControls()
        defer { page.controlsWindow?.close(); page.cleanUp() }
        let slider = try #require(page.controlsByID["dreams.rain-pulse-strength"] as? NSSlider)
        #expect(slider.minValue == 0 && slider.maxValue == 1)
        for value in [0.0, 0.62, 1.0] {
            slider.doubleValue = value
            page.changePulseStrength(slider)
            let reloaded = DreamsController()
            defer { reloaded.cleanUp() }
            #expect(reloaded.rainPulseStrength == value)
            #expect(try controller.status()["rain_pulse_strength"] as? Double == value)
        }
        let model = NativeSettingsModel(owner: page)
        model[parameter: .pulse] = 0.37
        #expect(slider.doubleValue == 0.37)
        #expect(controller.rainPulseStrength == 0.37)
    }
}
