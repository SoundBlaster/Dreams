import AppKit
import SwiftUI

extension SettingsPageController {
    func showNativeControls() {
        if nativeWindow == nil {
            let model = NativeSettingsModel(owner: self)
            let window = DreamsControlsWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "Dreams"
            window.identifier = NSUserInterfaceItemIdentifier("dreams.native-settings")
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 560, height: 450)
            window.onEscape = { [weak self] in self?.controller.handleEscape() }
            window.contentView = NSHostingView(rootView: NativeSettingsPage(model: model))
            nativeModel = model
            nativeWindow = window
            let observer = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification,
                object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.nativeWindowFocused() }
            }
            settingsObservers.append(observer)
            window.center()
            ensureActivityUpdates()
        }
        controller.stopForReopen()
        nativeModel?.refresh()
        refreshActivityLabel()
        NSApplication.shared.activate(ignoringOtherApps: true)
        nativeWindow?.makeKeyAndOrderFront(nil)
        nativeModel?.preview.refresh()
    }

    @objc private func nativeWindowFocused() {
        nativeModel?.refresh()
        refreshActivityLabel()
    }
}
