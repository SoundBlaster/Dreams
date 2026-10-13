import AppKit
import Testing
@testable import Dreams

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_DROP_SETTINGS"] == "1"))
@MainActor
struct DropDecelerationSettingsTests {
    @Test func controlsEnablePersistAndDisableDeceleration() throws {
        let previousApplication = NSWorkspace.shared.frontmostApplication
        defer { previousApplication?.activate(options: []) }
        _ = NSApplication.shared
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        #expect(Bundle.main.bundleIdentifier != "ru.egormerkushev.dreams")
        let defaults = UserDefaults.standard
        let keys = ["rainDecelerationEnabled", "rainDeceleration"]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        defaults.set(false, forKey: keys[0])
        defaults.set(-12.0, forKey: keys[1])
        let delegate = DreamsDelegate()
        delegate.showsControls = true
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        let window = try #require(NSApplication.shared.windows.first { $0.title == "Dreams" })
        defer {
            window.orderOut(nil)
            delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
        }
        let content = try #require(window.contentView)
        func find(_ id: String, in view: NSView) -> NSView? {
            if view.accessibilityIdentifier() == id { return view }
            return view.subviews.lazy.compactMap { find(id, in: $0) }.first
        }
        let enabled = try #require(find("dreams.rain-deceleration-enabled", in: content) as? NSButton)
        let acceleration = try #require(find("dreams.rain-deceleration", in: content) as? NSSlider)
        #expect(enabled.state == .off && !acceleration.isEnabled)
        enabled.performClick(nil)
        #expect(delegate.controller.rainDecelerationEnabled && acceleration.isEnabled)
        acceleration.doubleValue = -24.5
        try #require(NSApplication.shared.sendAction(try #require(acceleration.action),
                                                    to: acceleration.target, from: acceleration))
        #expect(delegate.controller.rainDeceleration == -24.5)
        #expect(defaults.bool(forKey: keys[0]))
        #expect(defaults.double(forKey: keys[1]) == -24.5)
        let reloaded = DreamsController()
        #expect(reloaded.rainDecelerationEnabled && reloaded.rainDeceleration == -24.5)
        reloaded.cleanUp()

        content.layoutSubtreeIfNeeded()
        enabled.performClick(nil)
        #expect(!delegate.controller.rainDecelerationEnabled && !acceleration.isEnabled)
        #expect(delegate.controller.rainDeceleration == -24.5)
    }
}
