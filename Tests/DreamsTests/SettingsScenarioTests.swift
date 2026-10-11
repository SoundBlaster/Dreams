import AppKit
import ScreenerKit
import Testing
@testable import Dreams

extension SettingsPageTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_RECORD_GUI"] == "1"))
    func recordedSettingsScenario() async throws {
        _ = NSApplication.shared
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"],
            "Run make test-gui-trace to use a disposable agent feed.")
        #expect(Bundle.main.bundleIdentifier != "ru.egormerkushev.dreams")
        let keys = ["transparentBackground", "rainColumnCount", "rainDensity", "rainSpeed", "rainFadeRows",
                    "rainBrightnessSpread", "rainGlow", "transparentRainGlow", "rainIdleIntensity", "rainColor",
                    "transparentRainColor", "keywordColor", "keywordBrightness", "restoredGlyphs", "hideFromScreenshots",
                    "runTimeSeconds", "stopHotkeyKeyCode", "stopHotkeyModifiers", "stopHotkeyKey"]
        let defaults = UserDefaults.standard
        let saved = Dictionary(uniqueKeysWithValues: keys.compactMap { key in defaults.object(forKey: key).map { (key, $0) } })
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller)
        defer {
            page.controlsWindow?.close()
            page.cleanUp()
            for key in keys {
                if let value = saved[key] { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        try controller.resetToDefaults()
        page.showControls()
        let window = try #require(page.controlsWindow)
        let content = try #require(window.contentView)
        let recorder = Screener()
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let traces = ProcessInfo.processInfo.environment["DREAMS_TRACE_DIRECTORY"].map { URL(fileURLWithPath: $0) }
            ?? caches.appending(path: "Screener/Traces")
        let trace = try await recorder.startSession(name: "Dreams-FSD-settings",
            appBundleID: "ru.egormerkushev.dreams.gui-tests", tracesDirectory: traces)
        let capture = ScreenerCaptureSession(screener: recorder)
        func checkpoint(_ name: String) async throws {
            page.refreshActivityLabel()
            content.layoutSubtreeIfNeeded()
            content.displayIfNeeded()
            try await recorder.mark(name, metadata: ["backend": "AppKit view capture", "actions": "native target/action"])
            try await capture.capture(from: AppKitCaptureSource(view: content), reason: name)
        }
        func fire(_ control: NSControl) throws {
            let action = try #require(control.action)
            #expect(NSApplication.shared.sendAction(action, to: control.target, from: control))
        }
        func slider(_ id: String, _ value: Double) throws {
            let control = try #require(page.controlsByID[id] as? NSSlider)
            control.doubleValue = value
            try fire(control)
        }
        func checkbox(_ id: String, _ enabled: Bool) throws {
            let control = try #require(page.controlsByID[id] as? NSButton)
            control.state = enabled ? .on : .off
            try fire(control)
        }
        do {
            try await checkpoint("01.Settings.initial")
            try checkbox("dreams.rain-columns-auto", false)
            try slider("dreams.rain-columns", 24)
            #expect(controller.rainColumnCount == 24)
            #expect(page.columnsLabel.stringValue == "24")
            try await checkpoint("02.Columns.minimum")
            try slider("dreams.rain-columns", 240)
            #expect(controller.rainColumnCount == 240)
            try await checkpoint("03.Columns.maximum")
            try checkbox("dreams.rain-columns-auto", true)
            #expect(controller.rainColumnCount == 0)
            #expect(page.controlsByID["dreams.rain-columns"]?.isEnabled == false)
            try await checkpoint("04.Columns.automatic")

            for (id, low, high, key) in [
                ("dreams.rain-density", 0.0, 1.0, "rain_density"),
                ("dreams.rain-speed", 0.25, 3.0, "rain_speed"),
                ("dreams.rain-fade", 1.0, 16.0, "rain_fade_rows"),
                ("dreams.rain-brightness-spread", 0.0, 1.0, "rain_brightness_spread"),
                ("dreams.rain-glow", 0.0, 3.0, "rain_glow"),
                ("dreams.rain-idle", 0.0, 1.0, "rain_idle_intensity"),
                ("dreams.keyword-brightness", 0.0, 2.0, "keyword_brightness")
            ] {
                for value in [low, high] {
                    try slider(id, value)
                    #expect(try controller.status()[key] as? Double == value)
                }
            }
            try await checkpoint("05.Sliders.maximums")
            try slider("dreams.rain-speed", 0.43)
            try slider("dreams.rain-density", 0.6)
            try slider("dreams.rain-glow", 0.63)
            try checkbox("dreams.rain-columns-auto", false)
            try slider("dreams.rain-columns", 80)
            let opaqueColor = NSColor(srgbRed: 0.1, green: 0.65, blue: 0.3, alpha: 1)
            let colorWell = try #require(page.rainColorWell)
            colorWell.color = opaqueColor
            try fire(colorWell)
            let wordColor = try #require(page.controlsByID["dreams.keyword-color"] as? NSColorWell)
            wordColor.color = NSColor(srgbRed: 0.8, green: 0.9, blue: 0.6, alpha: 1)
            try fire(wordColor)
            #expect(controller.keywordColor == wordColor.color)
            let runTime = try #require(page.controlsByID["dreams.run-time"] as? NSPopUpButton)
            for (index, seconds) in DreamsPreset.runTimeChoices.enumerated() {
                runTime.selectItem(at: index)
                try fire(runTime)
                #expect(controller.runTimeSeconds == seconds)
            }
            runTime.selectItem(at: 0)
            try fire(runTime)
            #expect(controller.runTimeSeconds == 300)
            try checkbox("dreams.transparent-background", true)
            #expect(runTime.isEnabled == false)
            #expect(controller.rainGlow == 0)
            try slider("dreams.rain-glow", 0.12)
            colorWell.color = NSColor(srgbRed: 0.4, green: 0.9, blue: 0.5, alpha: 1)
            try fire(colorWell)
            try await checkpoint("06.Transparent.separateGlowAndColor")
            try checkbox("dreams.transparent-background", false)
            #expect(runTime.isEnabled)
            #expect(controller.rainGlow == 0.63)
            #expect(colorWell.color == opaqueColor)
            try checkbox("dreams.transparent-background", true)
            #expect(controller.rainGlow == 0.12)
            try checkbox("dreams.transparent-background", false)
            try checkbox("dreams.hide-from-screenshots", false)
            #expect(controller.hideFromScreenshots == false)
            try checkbox("dreams.hide-from-screenshots", true)
            #expect(controller.hideFromScreenshots)
            try checkbox("dreams.restored-glyphs", false)
            #expect(controller.restoredGlyphs == false)
            try checkbox("dreams.restored-glyphs", true)
            #expect(controller.restoredGlyphs)
            try await checkpoint("07.Opaque.settingsRestored")

            let hotkey = try #require(page.hotkeyButton)
            hotkey.performClick(nil)
            #expect(page.hotkeyMonitor != nil)
            try await checkpoint("08.Hotkey.recording")
            hotkey.performClick(nil)
            #expect(page.hotkeyMonitor == nil)
            #expect(hotkey.title == controller.stopHotkey.display)
            try await checkpoint("09.Hotkey.cancelled")

            try KeywordFeed().publish(sessionID: "gui-fixture", words: ["GUI", "TEST"], ttl: 15)
            page.refreshActivityLabel()
            #expect(try controller.status()["working_agents"] as? Int == 1)
            try await checkpoint("10.Agent.working")
            try KeywordFeed().clear(sessionID: "gui-fixture")
            page.refreshActivityLabel()
            #expect(try controller.status()["working_agents"] as? Int == 0)
            try await checkpoint("11.Agent.idle")

            let timer = page.activityTimer
            window.close()
            page.showControls()
            #expect(page.controlsWindow === window)
            #expect(page.activityTimer === timer)
            #expect(page.controlsByID.count == 15)
            try await checkpoint("12.Window.closedAndReopened")
            try controller.resetToDefaults()
            page.syncControls()
            #expect(controller.rainColumnCount == 0)
            #expect(controller.transparentBackground == false)
            #expect((page.controlsByID["dreams.transparent-background"] as? NSButton)?.state == .off)
            #expect((page.controlsByID["dreams.rain-columns-auto"] as? NSButton)?.state == .on)
            try await checkpoint("13.Defaults.synchronized")
            page.cleanUp()
            #expect(page.focusObserver == nil)
            #expect(page.activityTimer?.isValid == false)
            try await recorder.mark("14.Cleanup.complete", metadata: ["settingsRestoredByDefer": "true"])
            try await recorder.stopSession()
            print("DREAMS_GUI_TRACE=\(trace.path)")
        } catch {
            try? await recorder.mark("Scenario.failed", metadata: ["error": String(describing: error)])
            try? await recorder.stopSession()
            throw error
        }
    }

}
