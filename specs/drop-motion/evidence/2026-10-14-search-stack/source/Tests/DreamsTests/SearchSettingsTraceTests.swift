import AppKit
import ScreenerKit
import Testing
@testable import Dreams

/// Opt-in appearance evidence, separate from the synchronous settings assertions.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["DREAMS_CAPTURE_SEARCH_SETTINGS"] == "1"))
@MainActor
struct SearchSettingsTraceTests {
    @Test func captureSearchControl() async throws {
        _ = NSApplication.shared
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        #expect(Bundle.main.bundleIdentifier != "ru.egormerkushev.dreams")
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: "rainSearchFraction")
        let previousApplication = NSWorkspace.shared.frontmostApplication
        defaults.set(0.1, forKey: "rainSearchFraction")
        defer {
            if let saved { defaults.set(saved, forKey: "rainSearchFraction") }
            else { defaults.removeObject(forKey: "rainSearchFraction") }
            previousApplication?.activate(options: [])
        }
        let delegate = DreamsDelegate()
        delegate.showsControls = true
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        let window = try #require(NSApplication.shared.windows.first { $0.title == "Dreams" })
        let content = try #require(window.contentView)
        defer {
            window.orderOut(nil)
            delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
        }
        content.layoutSubtreeIfNeeded()
        content.displayIfNeeded()
        let recorder = Screener()
        let trace = try await recorder.startSession(name: "Dreams-search-occupancy",
            appBundleID: "ru.egormerkushev.dreams.search-tests",
            tracesDirectory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appending(path: "Screener/Traces"))
        do {
            try await recorder.mark("Search.default10percent", metadata: ["fraction": "0.1"])
            try await ScreenerCaptureSession(screener: recorder)
                .capture(from: AppKitCaptureSource(view: content), reason: "Search.default10percent")
            try await recorder.stopSession()
            print("DREAMS_SEARCH_TRACE=\(trace.path)")
        } catch {
            try? await recorder.stopSession()
            throw error
        }
    }
}
