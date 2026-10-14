import AppKit
import Testing
@testable import Dreams

@Suite(.serialized)
@MainActor
struct SettingsPageTests {
    @Test func settingsWindowKeepsControlsAndValues() throws {
        _ = NSApplication.shared
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller)
        page.showControls()
        defer {
            page.controlsWindow?.close()
            page.cleanUp()
        }
        let window = try #require(page.controlsWindow)
        #expect(window.title == "Dreams")
        #expect(window.contentView?.subviews.first is NSScrollView)
        #expect(Set(page.controlsByID.keys) == Set([
            "dreams.run-time", "dreams.rain-columns-auto", "dreams.rain-columns", "dreams.rain-color",
            "dreams.rain-search-fraction", "dreams.rain-deceleration", "dreams.rain-deceleration-enabled",
            "dreams.rain-density", "dreams.rain-speed", "dreams.rain-fade", "dreams.rain-brightness-spread",
            "dreams.rain-glow", "dreams.rain-idle", "dreams.transparent-background", "dreams.hide-from-screenshots",
            "dreams.keyword-color", "dreams.keyword-brightness", "dreams.restored-glyphs"
        ]))
        for control in page.controlsByID.values {
            #expect(control.target === page)
            let action = try #require(control.action)
            #expect(page.responds(to: action))
        }
        let slider = try #require(page.controlsByID["dreams.rain-columns"] as? NSSlider)
        #expect(slider.minValue == 24)
        #expect(slider.maxValue == 240)
        #expect(slider.isEnabled == (controller.rainColumnCount != 0))
        #expect(slider.doubleValue == Double(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount))
        let glow = try #require(page.controlsByID["dreams.rain-glow"] as? NSSlider)
        #expect(glow === page.glowSlider)
        #expect(glow.doubleValue == controller.rainGlow)
        let transparent = try #require(page.controlsByID["dreams.transparent-background"] as? NSButton)
        #expect(transparent.state == (controller.transparentBackground ? .on : .off))
        #expect(page.hookButtons.keys.sorted() == ["claude", "codex"])
        #expect(page.hotkeyButton?.title == controller.stopHotkey.display)
        #expect(page.activityTimer?.isValid == true)
        #expect(page.focusObserver != nil)
        page.cleanUp()
        #expect(page.activityTimer?.isValid == false)
        #expect(page.focusObserver == nil)
    }
}
