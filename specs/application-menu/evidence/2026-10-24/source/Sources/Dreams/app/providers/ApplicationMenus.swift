import AppKit

/// The interactive app's standard menu bar, separate from the agent/status-item menu.
@MainActor
struct ApplicationMenus {
    let main = NSMenu()
    let services = NSMenu(title: L("appMenu.services"))
    let windows = NSMenu(title: L("appMenu.window"))

    init(settingsTarget: AnyObject, settingsAction: Selector) {
        let app = NSApplication.shared
        let application = NSMenu(title: "Dreams")
        application.addItem(withTitle: L("appMenu.about"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
            .target = app
        application.addItem(.separator())
        let settings = application.addItem(withTitle: L("appMenu.settings"), action: settingsAction, keyEquivalent: ",")
        settings.target = settingsTarget
        application.addItem(.separator())
        application.addItem(withTitle: L("appMenu.services"), action: nil, keyEquivalent: "").submenu = services
        application.addItem(.separator())
        application.addItem(withTitle: L("appMenu.hide"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h").target = app
        let hideOthers = application.addItem(withTitle: L("appMenu.hideOthers"),
                                            action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        hideOthers.target = app
        application.addItem(withTitle: L("appMenu.showAll"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
            .target = app
        application.addItem(.separator())
        application.addItem(withTitle: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q").target = app
        main.addItem(withTitle: "Dreams", action: nil, keyEquivalent: "").submenu = application

        let edit = NSMenu(title: L("appMenu.edit"))
        edit.addItem(withTitle: L("appMenu.undo"), action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: L("appMenu.redo"), action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: L("appMenu.cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: L("appMenu.copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: L("appMenu.paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: L("appMenu.selectAll"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        // nil targets preserve AppKit's responder-chain validation, including native text fields.
        main.addItem(withTitle: edit.title, action: nil, keyEquivalent: "").submenu = edit

        windows.addItem(withTitle: L("appMenu.close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windows.addItem(withTitle: L("appMenu.minimize"), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windows.addItem(withTitle: L("appMenu.zoom"), action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windows.addItem(.separator())
        windows.addItem(withTitle: L("appMenu.bringAllToFront"), action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
            .target = app
        main.addItem(withTitle: windows.title, action: nil, keyEquivalent: "").submenu = windows
    }

    func install(in application: NSApplication) {
        application.mainMenu = main
        application.servicesMenu = services
        application.windowsMenu = windows
    }
}
