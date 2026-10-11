import AppKit

/// App composition owns lifecycle, the menu bar and the settings page.
@MainActor
final class DreamsDelegate: NSObject, NSApplicationDelegate {
    let controller = DreamsController()
    var showsControls = false
    private lazy var settings = SettingsPageController(controller: controller)
    private var statusItem: NSStatusItem?
    private var stopMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        if showsControls { settings.showControls() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if showsControls { settings.showControls() }
        return true
    }

    func setupMenu() {
        settings.installShortcuts()
        settings.onHotkeyChange = { [weak self] in self?.refreshStopMenuItem() }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let icon = StatusIcon.image() { item.button?.image = icon }
        else { item.button?.title = "◒" }
        item.button?.setAccessibilityLabel("Dreams")
        let menu = NSMenu()
        if showsControls {
            menu.addItem(withTitle: L("menu.openControls"), action: #selector(showControls), keyEquivalent: "")
            menu.addItem(.separator())
        }
        menu.addItem(withTitle: L("menu.startMatrix"), action: #selector(start), keyEquivalent: "")
        stopMenuItem = menu.addItem(withTitle: L("menu.stop"), action: #selector(stop), keyEquivalent: "")
        refreshStopMenuItem()
        menu.addItem(.separator())
        let debug = menu.addItem(withTitle: L("debug.menu"), action: nil, keyEquivalent: "")
        debug.submenu = settings.debugMenu()
        menu.addItem(.separator())
        menu.addItem(withTitle: L("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        for menuItem in menu.items where menuItem.submenu == nil { menuItem.target = self }
        item.menu = menu
        statusItem = item
    }

    private func refreshStopMenuItem() {
        let equivalent = controller.stopHotkey.menuEquivalent
        stopMenuItem?.keyEquivalent = equivalent?.key ?? ""
        stopMenuItem?.keyEquivalentModifierMask = equivalent?.flags ?? []
    }

    @objc private func showControls() { settings.showControls() }
    @objc private func start() { settings.start() }
    @objc private func stop() { settings.stop() }
    @objc private func quit() { NSApplication.shared.terminate(nil) }

    func show(error: Error) { settings.show(error: error) }

    func applicationWillTerminate(_ notification: Foundation.Notification) {
        settings.cleanUp()
    }
}
