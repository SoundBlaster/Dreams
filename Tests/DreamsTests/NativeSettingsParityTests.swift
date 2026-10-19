import AppKit
import Carbon.HIToolbox
import Testing
@testable import Dreams

extension NativeSettingsTests {
    @Test func displayTitlesIdentifyBuiltInMainAndExcludedDisplays() {
        let ordinary = RainDisplay(id: "external", name: "External", builtIn: false, isMain: false, excluded: false)
        let internalMain = RainDisplay(id: "internal", name: "Retina", builtIn: true, isMain: true, excluded: false)
        let workspace = RainDisplay(id: "workspace", name: "Agent", builtIn: false, isMain: false, excluded: true)
        #expect(ordinary.settingsTitle == "External")
        #expect(internalMain.settingsTitle == "Retina · " + L("display.builtIn") + " · " + L("display.main"))
        #expect(workspace.settingsTitle == "Agent · " + L("display.agentWorkspace"))
    }

    @Test(arguments: [0.0, 300, 1800, 3600], [false, true])
    func runtimeHintMatchesBackgroundDurationAndShortcut(seconds: Double, transparent: Bool) throws {
        _ = NSApplication.shared
        let restore = Self.preserveDefaults()
        defer { restore() }
        let controller = DreamsController()
        let page = SettingsPageController(controller: controller)
        defer { page.cleanUp() }
        let model = NativeSettingsModel(owner: page)
        model.runTime = seconds
        model.transparent = transparent
        let shortcut = StopHotkey(keyCode: UInt32(kVK_F17), modifiers: UInt32(controlKey | optionKey | cmdKey | shiftKey), key: "F17")
        controller.stopHotkey = shortcut
        let expected = transparent ? L("hint.runtime.transparent", shortcut.display)
            : seconds > 0 ? L("hint.runtime", SettingsPageController.runTimeTitle(seconds).lowercased(), shortcut.display)
            : L("hint.runtime.unlimited", shortcut.display)
        #expect(model.runTimeHint == expected)
    }

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
