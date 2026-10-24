import AppKit
import Testing
@testable import Dreams

extension NativeSettingsTests {
    @Test(arguments: [false, true])
    func appearanceRecipesUseSavedValuesWithoutChangingMotion(transparent: Bool) throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller, nativeSettingsEnabled: true)
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        defer { page.cleanUp() }
        model.transparent = transparent
        controller.rainSpeed = 0.87
        controller.rainColumnCount = 91
        controller.rainDensity = 0.42
        let defaults = UserDefaults.standard
        let inactiveColorKey = transparent ? "rainColor" : "transparentRainColor"
        let inactiveGlowKey = transparent ? "rainGlow" : "transparentRainGlow"
        let inactiveColor = defaults.array(forKey: inactiveColorKey) as? [Double]
        let inactiveGlow = defaults.object(forKey: inactiveGlowKey) as? Double
        for preset in NativeAppearancePreset.allCases {
            model.applyAppearance(preset)
            #expect(model.appearancePreset == preset)
            #expect(controller.rainSpeed == 0.87 && controller.rainColumnCount == 91 && controller.rainDensity == 0.42)
            #expect(defaults.array(forKey: inactiveColorKey) as? [Double] == inactiveColor)
            #expect(defaults.object(forKey: inactiveGlowKey) as? Double == inactiveGlow)
            let reloaded = DreamsController()
            // The launch profile is cached per process; request this profile explicitly in-process.
            try reloaded.setTransparentBackground(transparent)
            #expect(preset.values(transparent: transparent).matches(color: reloaded.rainColor, glow: reloaded.rainGlow,
                spread: reloaded.rainBrightnessSpread, pulse: reloaded.rainPulseStrength))
        }
        model[parameter: .pulse] = 0.77
        #expect(model.appearancePreset == nil)
        model.applyAppearance(.classic)
        #expect(model.appearancePreset == .classic)
    }

    @Test func quickPaletteChangesOnlyActiveColorAndManualColorClearsSelection() throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller, nativeSettingsEnabled: true)
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        defer { page.cleanUp() }
        model.applyAppearance(.classic)
        let glow = controller.rainGlow, spread = controller.rainBrightnessSpread, pulse = controller.rainPulseStrength
        for swatch in NativeRainSwatch.allCases {
            model.applyColor(swatch)
            #expect(model.isSelected(swatch))
            #expect(NativeRainSwatch.allCases.filter { model.isSelected($0) }.count == 1)
            #expect(controller.rainGlow == glow && controller.rainBrightnessSpread == spread && controller.rainPulseStrength == pulse)
            #expect(model.appearancePreset == nil)
        }
        model.rainColor = .init(.sRGB, red: 0.123, green: 0.456, blue: 0.789, opacity: 1)
        #expect(!NativeRainSwatch.allCases.contains { model.isSelected($0) })
        #expect(model.appearancePreset == nil)
    }
}
