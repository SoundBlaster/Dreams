import AppKit
import Carbon.HIToolbox
import Testing
@testable import Dreams

extension NativeSettingsTests {
    @Test func failedResetReconcilesThePartiallyChangedStopShortcut() throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller)
        let probe = EmergencyHotkey()
        defer { page.cleanUp(); probe.uninstall() }
        let previous = StopHotkey(keyCode: UInt32(kVK_F17), modifiers: UInt32(controlKey | optionKey | cmdKey | shiftKey), key: "F17")
        let target = StopHotkey(keyCode: UInt32(kVK_F18), modifiers: UInt32(controlKey | optionKey | cmdKey | shiftKey), key: "F18")
        page.applyStopHotkey(previous)
        try #require(controller.stopHotkey == previous && controller.emergencyHotkeyRegistered)
        let failure = NSError(domain: "DreamsResetParityTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Display reset failed"])
        // A reset may save a new shortcut before display reconciliation throws.
        let model = NativeSettingsModel(owner: page, resetToDefaults: {
            controller.stopHotkey = target
            throw failure
        })
        page.nativeModel = model
        model.reset()
        #expect(model.errorMessage == failure.localizedDescription)
        #expect(controller.stopHotkey == target && StopHotkey.load() == target)
        #expect(probe.change(to: previous), "The old registration must be released after a partial reset")
        probe.uninstall()
        #expect(!probe.change(to: target), "The saved shortcut must be registered despite the later reset error")
    }
}
