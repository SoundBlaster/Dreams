import AppKit
import Testing
import ScreenerKit
@testable import Dreams

/// Opt-in native settings trace; live display topology is exercised by scripts/test-displays.py.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_DISPLAYS"] == "1"))
@MainActor
struct DisplaySettingsTraceTests {
    @Test func displaySettingsPersistAndExplainFallback() async throws {
        _ = NSApplication.shared
        let keys = ["rainDisplayMode", "rainDisplayIDs", "rainSpeed", "rainGlow", "transparentBackground"]
        let defaults = UserDefaults.standard
        let saved = keys.map { ($0, defaults.object(forKey: $0)) }
        defer { for (key, value) in saved { defaults.set(value, forKey: key) } }
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"], "Use a disposable agent feed")
        #expect(Bundle.main.bundleIdentifier != "ru.egormerkushev.dreams")
        let delegate = DreamsDelegate()
        let controller = delegate.controller
        delegate.showsControls = true
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        let window = try #require(NSApplication.shared.windows.first { $0.title == "Dreams" })
        let content = try #require(window.contentView)
        defer {
            window.close()
            delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
        }
        try controller.setDisplaySelection(.init(mode: .all))
        func findControls(in view: NSView) -> DisplaySettingsView? {
            (view as? DisplaySettingsView) ?? view.subviews.lazy.compactMap { findControls(in: $0) }.first
        }
        let view = try #require(findControls(in: content))
        #expect(view.modePopup.indexOfSelectedItem == 1)

        let recorder = Screener()
        let trace = try await recorder.startSession(name: "Dreams-display-management",
            appBundleID: "ru.egormerkushev.dreams.display-tests",
            tracesDirectory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "Screener/Traces"))
        let capture = ScreenerCaptureSession(screener: recorder)
        func checkpoint(_ name: String) async throws {
            content.layoutSubtreeIfNeeded()
            content.displayIfNeeded()
            try await recorder.mark(name, metadata: ["backend": "AppKit", "actions": "native target/action"])
            try await capture.capture(from: AppKitCaptureSource(view: content), reason: name)
        }
        do {
            view.modePopup.selectItem(at: 0)
            view.changeMode(view.modePopup)
            try await checkpoint("01.Automatic")
            view.modePopup.selectItem(at: 1)
            view.changeMode(view.modePopup)
            #expect(view.displayButtons.values.allSatisfy { !$0.isEnabled })
            try await checkpoint("02.AllDisplays")
            view.modePopup.selectItem(at: 2)
            view.changeMode(view.modePopup)
            #expect(controller.displaySelection.mode == .selected)
            #expect(!controller.displaySelection.selectedIDs.isEmpty)
            try await checkpoint("03.SelectedDisplays")
            for button in view.displayButtons.values {
                button.state = .off
                view.toggleDisplay(button)
            }
            #expect(controller.displaySelection.selectedIDs.isEmpty)
            #expect(view.hint.stringValue.contains(L("display.fallback")))
            try await checkpoint("04.EmptySelectionFallback")
            let first = try #require(view.displayButtons.values.first { $0.isEnabled })
            first.state = .on
            view.toggleDisplay(first)
            #expect(controller.displaySelection.selectedIDs.count == 1)
            #expect(RainDisplaySelection.load() == controller.displaySelection)
            try controller.setDisplaySelection(.init())
            #expect(view.modePopup.indexOfSelectedItem == 0)
            try await checkpoint("05.AutomaticRestored")
            try await recorder.stopSession()
            print("DREAMS_DISPLAY_TRACE=\(trace.path)")
        } catch {
            try? await recorder.mark("Scenario.failed", metadata: ["error": String(describing: error)])
            try? await recorder.stopSession()
            throw error
        }
    }

}
