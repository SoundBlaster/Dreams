import AppKit
import Carbon.HIToolbox
import Testing
@testable import Dreams

// Extend the serialized settings suite: these checks share AppKit and UserDefaults.
extension NativeSettingsTests {
    private func shortcutWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }

    private func key(_ code: Int, in window: NSWindow, flags: NSEvent.ModifierFlags = [], text: String = "d") throws -> NSEvent {
        try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags,
            timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: text,
            charactersIgnoringModifiers: text, isARepeat: false, keyCode: UInt16(code)))
    }

    @Test func extendedFunctionKeysHaveReadableNames() throws {
        _ = NSApplication.shared
        let window = shortcutWindow()
        defer { window.close() }
        for (index, code) in [kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20].enumerated() {
            let shortcut = try #require(StopHotkey(event: key(code, in: window, flags: [.control, .option, .command], text: "\u{f715}")))
            #expect(shortcut.display == "⌃⌥⌘F\(index + 13)")
            #expect(shortcut.menuEquivalent == nil)
        }
    }

    @Test func recordingConsumesOnlyItsWindowAndEscapeCancelsWithoutCommit() throws {
        _ = NSApplication.shared
        let window = shortcutWindow(), other = shortcutWindow()
        defer { window.close(); other.close() }
        let recorder = StopShortcutRecorder()
        defer { recorder.cancel() }
        var received: [StopHotkey] = []
        recorder.start(in: window) { received.append($0) }
        let foreign = try key(kVK_ANSI_D, in: other, flags: [.control, .option])
        #expect(recorder.handle(foreign) === foreign)
        #expect(recorder.isRecording)
        #expect(recorder.handle(try key(kVK_ANSI_D, in: window)) == nil)
        #expect(recorder.isRecording && recorder.message != nil)
        #expect(recorder.handle(try key(kVK_ANSI_D, in: window, flags: .shift)) == nil)
        #expect(recorder.isRecording)
        #expect(recorder.handle(try key(kVK_Escape, in: window)) == nil)
        #expect(!recorder.isRecording && received.isEmpty)
        #expect(recorder.message == nil)
        let normal = try key(kVK_ANSI_D, in: window)
        #expect(recorder.handle(normal) === normal)
    }

    @Test func recordingCommitsOnceAndRemovesLifecycleObservers() throws {
        _ = NSApplication.shared
        let window = shortcutWindow()
        defer { window.close() }
        let recorder = StopShortcutRecorder()
        var received: [StopHotkey] = []
        recorder.start(in: window) { received.append($0) }
        let event = try key(kVK_ANSI_D, in: window, flags: [.control, .option, .command])
        #expect(recorder.handle(event) == nil)
        #expect(received == [.standard])
        #expect(!recorder.isRecording)
        #expect(recorder.handle(event) === event)
        #expect(received.count == 1)
        recorder.message = "registration error"
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        #expect(recorder.message == "registration error") // no stale observer after finishing
    }

    @Test func recordingCancelsOnCloseFocusLossAndAppDeactivation() {
        _ = NSApplication.shared
        let window = shortcutWindow()
        defer { window.close() }
        let recorder = StopShortcutRecorder()
        for (name, object) in [
            (NSWindow.willCloseNotification, window as AnyObject),
            (NSWindow.didResignKeyNotification, window as AnyObject),
            (NSApplication.didResignActiveNotification, NSApplication.shared as AnyObject),
            (NSApplication.didHideNotification, NSApplication.shared as AnyObject)
        ] {
            recorder.start(in: window) { _ in Issue.record("Cancellation must not commit") }
            NotificationCenter.default.post(name: name, object: object)
            #expect(!recorder.isRecording)
        }
    }

    @Test func nativeAndLegacyRecordingShareOwnerAndCleanup() throws {
        _ = NSApplication.shared
        let page = SettingsPageController(controller: DreamsController())
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        page.nativeWindow = DreamsControlsWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        page.nativeWindow?.isReleasedWhenClosed = false
        defer { page.cleanUp() }
        model.recordShortcut()
        #expect(model.isRecordingShortcut)
        let button = NSButton()
        page.recordHotkey(button) // second activation cancels even from the other presentation
        #expect(!model.isRecordingShortcut)
        model.recordShortcut()
        model.cancelShortcutRecording() // native navigation cancellation
        #expect(!model.isRecordingShortcut)
        model.recordShortcut()
        page.cleanUp()
        #expect(!model.isRecordingShortcut)
    }

    @Test func occupiedShortcutKeepsSavedValueAndShowsNativeError() throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let page = SettingsPageController(controller: DreamsController())
        let model = NativeSettingsModel(owner: page)
        page.nativeModel = model
        let blocker = EmergencyHotkey()
        defer { page.cleanUp(); blocker.uninstall() }
        // An unusual test-only chord; never replace the user's registered global exit key.
        let occupied = StopHotkey(keyCode: UInt32(kVK_F17), modifiers: UInt32(controlKey | optionKey | cmdKey | shiftKey), key: "F17")
        try #require(blocker.change(to: occupied))
        let previous = page.controller.stopHotkey
        let saved = StopHotkey.load()
        page.applyStopHotkey(occupied)
        #expect(page.controller.stopHotkey == previous)
        #expect(StopHotkey.load() == saved)
        #expect(model.shortcutMessage == L("hotkey.taken", occupied.display))
        blocker.uninstall()
        page.applyStopHotkey(occupied)
        #expect(page.controller.stopHotkey == occupied)
        #expect(StopHotkey.load() == occupied)
        #expect(model.stopShortcut == occupied.display && model.shortcutMessage == nil)
    }
}
