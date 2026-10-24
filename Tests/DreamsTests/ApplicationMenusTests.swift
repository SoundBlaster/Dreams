import AppKit
import Testing
@testable import Dreams

@Suite(.serialized) @MainActor
struct ApplicationMenusTests {
    final class SettingsTarget: NSObject {
        var opened = false
        @objc func showSettings(_ sender: Any?) { opened = true }
    }

    @Test func appMenuHasNativeActionsAndSettingsShortcut() throws {
        let target = SettingsTarget()
        let menus = ApplicationMenus(settingsTarget: target, settingsAction: #selector(SettingsTarget.showSettings(_:)))
        let menu = try #require(menus.main.items.first?.submenu)
        #expect(menu.items.contains { $0.action == #selector(NSApplication.orderFrontStandardAboutPanel(_:)) })
        #expect(menu.items.contains { $0.action == #selector(NSApplication.hide(_:)) && $0.keyEquivalent == "h" })
        #expect(menu.items.contains { $0.action == #selector(NSApplication.terminate(_:)) && $0.keyEquivalent == "q" })
        let settings = try #require(menu.items.first { $0.keyEquivalent == "," })
        #expect(settings.keyEquivalentModifierMask == .command)
        #expect(NSApplication.shared.sendAction(try #require(settings.action), to: settings.target, from: settings))
        #expect(target.opened)
        #expect(menu.items.contains { $0.submenu === menus.services })
    }

    @Test func editAndWindowCommandsUseTheResponderChain() throws {
        let target = SettingsTarget()
        let menus = ApplicationMenus(settingsTarget: target, settingsAction: #selector(SettingsTarget.showSettings(_:)))
        let edit = try #require(menus.main.items.dropFirst().first?.submenu)
        for key in ["z", "x", "c", "v", "a"] {
            let item = try #require(edit.items.first { $0.keyEquivalent == key })
            #expect(item.target == nil)
        }
        #expect(edit.items.contains { $0.keyEquivalent == "z" && $0.keyEquivalentModifierMask == [.command, .shift] })
        #expect(menus.windows.items.contains { $0.action == #selector(NSWindow.performClose(_:)) && $0.keyEquivalent == "w" })
        #expect(menus.windows.items.contains { $0.action == #selector(NSWindow.performMiniaturize(_:)) && $0.keyEquivalent == "m" })
    }
}
