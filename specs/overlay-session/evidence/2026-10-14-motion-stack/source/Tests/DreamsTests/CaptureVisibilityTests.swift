import AppKit
import Testing
@testable import Dreams

/// Opt-in native overlays with Metal; the capture observations and clock are deterministic.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_CAPTURE_STATUS"] == "1"))
@MainActor
struct CaptureVisibilityTests {
    @Test(arguments: [false, true])
    func captureSuspensionChangesVisibilityWithoutStoppingTheSession(transparent: Bool) throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        let keys = ["transparentBackground", "hideFromScreenshots"]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        let controller = DreamsController()
        defer { controller.stop() }
        try controller.setTransparentBackground(transparent)
        controller.setHideFromScreenshots(true)
        try controller.start(duration: 60)
        let initial = try controller.status()
        let initialWindows = try #require(initial["rain_windows"] as? [[String: Any]])
        let numbers = try initialWindows.map { try #require($0["window_number"] as? Int) }
        try #require(!numbers.isEmpty)
        let windows = try numbers.map { try #require(NSApplication.shared.window(withWindowNumber: $0)) }
        #expect(initial["rain_visible"] as? Bool == true)
        #expect(initial["rain_suspended_for_capture"] as? Bool == false)
        let start = Date(timeIntervalSinceReferenceDate: 1_000)

        func expectStatus(visible: Bool, suspended: Bool) throws {
            let status = try controller.status()
            #expect(status["rain_visible"] as? Bool == visible)
            #expect(status["rain_suspended_for_capture"] as? Bool == suspended)
            #expect(status["rain_requested"] as? Bool == true)
            #expect(status["expires_at"] as? String == initial["expires_at"] as? String)
            #expect(status["prevents_idle_sleep"] as? Bool == initial["prevents_idle_sleep"] as? Bool)
            #expect((status["rain_windows"] as? [[String: Any]])?.compactMap { $0["window_number"] as? Int } == numbers)
            #expect(windows.allSatisfy { $0.isVisible == visible })
        }
        controller.checkScreenshotTool(active: true, at: start)
        try expectStatus(visible: false, suspended: true)
        controller.checkScreenshotTool(active: false, at: start.addingTimeInterval(1))
        controller.checkScreenshotTool(active: false, at: start.addingTimeInterval(1.5))
        try expectStatus(visible: false, suspended: true)
        // A reappearing picker resets the clear grace period.
        controller.checkScreenshotTool(active: true, at: start.addingTimeInterval(1.6))
        controller.checkScreenshotTool(active: false, at: start.addingTimeInterval(2))
        controller.checkScreenshotTool(active: false, at: start.addingTimeInterval(2.6))
        try expectStatus(visible: true, suspended: false)
        // Opting into capture keeps the overlays presented even while a picker is active.
        controller.setHideFromScreenshots(false)
        controller.checkScreenshotTool(active: true, at: start.addingTimeInterval(3))
        try expectStatus(visible: true, suspended: false)
        controller.setHideFromScreenshots(true)
        controller.checkScreenshotTool(active: true, at: start.addingTimeInterval(4))
        try expectStatus(visible: false, suspended: true)
        // Reconciliation can remove the final overlay while retaining the requested
        // session. Exercise that ownership state without disconnecting real hardware.
        let manager = try #require(Mirror(reflecting: controller).children
            .first { $0.label == "screenManager" }?.value as? RainScreenManager)
        manager.close()
        controller.checkScreenshotTool(active: false, at: start.addingTimeInterval(5))
        let unavailable = try controller.status()
        #expect((unavailable["rain_windows"] as? [[String: Any]])?.isEmpty == true)
        #expect(unavailable["rain_requested"] as? Bool == true)
        #expect(unavailable["rain_visible"] as? Bool == false)
        #expect(unavailable["rain_suspended_for_capture"] as? Bool == false)
        controller.stop()
        let stopped = try controller.status()
        #expect(stopped["rain_visible"] as? Bool == false)
        #expect(stopped["rain_requested"] as? Bool == false)
        #expect(stopped["rain_suspended_for_capture"] as? Bool == false)
        #expect((stopped["rain_windows"] as? [[String: Any]])?.isEmpty == true)
        #expect(windows.allSatisfy { !$0.isVisible })
        #expect(stopped["prevents_idle_sleep"] as? Bool == false)
        #expect(stopped["expires_at"] is NSNull)
    }
}
