import AppKit

/// App composition owns lifecycle, the menu bar and the settings page.
@MainActor
final class DreamsDelegate: NSObject, NSApplicationDelegate {
    let controller = DreamsController()
    var showsControls = false
    var ownsDesktop = false
    private lazy var settings = SettingsPageController(controller: controller)
    private(set) var statusItem: NSStatusItem?
    private var stopMenuItem: NSMenuItem?
    private var menuVisibilityObserver: NSObjectProtocol?

    func applicationWillFinishLaunching(_ notification: Foundation.Notification) {
        guard showsControls else { return }
        ApplicationMenus(settingsTarget: self, settingsAction: #selector(showControls)).install(in: NSApplication.shared)
    }

    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        if showsControls { settings.showControls() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard ownsDesktop else { return false }
        reopenSettings()
        return true
    }

    /// A GUI launch may reopen an existing accessory controller instead of creating another rain.
    func reopenSettings() {
        guard ownsDesktop else { return }
        if !showsControls {
            showsControls = true
            NSApplication.shared.setActivationPolicy(.regular)
            ApplicationMenus(settingsTarget: self, settingsAction: #selector(showControls)).install(in: NSApplication.shared)
            if let menu = statusItem?.menu {
                menu.insertItem(.separator(), at: 0)
                let open = NSMenuItem(title: L("menu.openControls"), action: #selector(showControls), keyEquivalent: "")
                open.target = self
                menu.insertItem(open, at: 0)
            }
        }
        settings.showControls()
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
        refreshMenuBarVisibility()
        menuVisibilityObserver = NotificationCenter.default.addObserver(forName: DreamsController.settingsDidChange,
            object: controller, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshMenuBarVisibility() }
        }
    }

    private func refreshMenuBarVisibility() {
        statusItem?.isVisible = controller.showsMenuBarIcon
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
        if let menuVisibilityObserver { NotificationCenter.default.removeObserver(menuVisibilityObserver) }
        menuVisibilityObserver = nil
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        statusItem = nil
        settings.cleanUp()
    }
}
