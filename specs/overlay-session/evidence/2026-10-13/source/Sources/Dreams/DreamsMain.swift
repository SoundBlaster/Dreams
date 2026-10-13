            }
            return
        }
        SettingsMigration.run()
        let publisherOnly = CommandLine.arguments.contains("--publisher")
        let interactive = !CommandLine.arguments.contains("--mcp")
            && !CommandLine.arguments.contains("--lab")
            && !CommandLine.arguments.contains("--render-demo")
        let application = NSApplication.shared
        application.setActivationPolicy(interactive ? .regular : .accessory)
        // The normal app has a Dock icon while it runs: set it explicitly, so it never depends on
        // the icon cache of the Dock or Launch Services (a stale cache shows a blank placeholder).
        if interactive, let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            application.applicationIconImage = icon
        }
        let delegate = DreamsDelegate()
        delegate.showsControls = interactive
        application.delegate = delegate
        if !publisherOnly { delegate.setupMenu() }
        if CommandLine.arguments.contains("--mcp") {
            Task {
                do { try await runServer(controller: delegate.controller, publisherOnly: publisherOnly) }
                catch { FileHandle.standardError.write(Data("Dreams: \(error)\n".utf8)) }
                delegate.controller.cleanUp()
                application.terminate(nil)
            }
        } else if let index = CommandLine.arguments.firstIndex(of: "--render-demo") {
            Task {
                do {
                    guard CommandLine.arguments.indices.contains(index + 1) else {

            Tool(name: "dreams_clear_keywords", description: "Remove only the public keywords for the given session_id.", inputSchema: .object([
                "type": "object", "required": ["session_id"], "properties": .object([
                    "session_id": .object(["type": "string", "minLength": 1, "maxLength": 192])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_status", description: "Read rain, settings and virtual workspace state, display IDs, bounds and test click count.", inputSchema: emptySchema),
            Tool(name: "dreams_preview", description: "Render the rain and keyword feed to a PNG without capturing the screen. Does not show or hide the overlay.", inputSchema: emptySchema),
            Tool(name: "dreams_start", description: "Show Matrix rain on the displays selected in Settings (automatic by default: built-in, otherwise main). Covers screenshots of those displays. Use prepare_ui before ordinary desktop computer use. Auto-stops after duration_seconds (default 300, maximum 3600).", inputSchema: .object([
                "type": "object", "properties": .object([
                    "duration_seconds": .object(["type": "number", "minimum": 1, "maximum": 3600]),
                    "brightness": .object(["type": "number", "minimum": 0.02, "maximum": 0.35])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_stop", description: "Remove the rain immediately and release the display sleep assertion. Does not destroy the virtual workspace.", inputSchema: emptySchema),
            Tool(name: "dreams_prepare_ui", description: "Remove the rain BEFORE screenshots, clicks or keyboard actions on a covered desktop. The screen is unprotected during UI work. Resume afterward.", inputSchema: emptySchema),
            Tool(name: "dreams_resume", description: "Resume the rain using the last brightness and duration after UI work.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_create", description: "EXPERIMENTAL: create a separate virtual display using a private macOS API and show a harmless Increment test window. Does not move existing apps or guarantee native agent compatibility.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_close", description: "Close the test window and disconnect only the virtual display owned by this Dreams process. Other windows placed on it may move to a physical display.", inputSchema: emptySchema)
        ]
        // swiftlint:enable line_length
        if publisherOnly {
            tools = tools.filter { ["dreams_status", "dreams_preview", "dreams_publish_keywords", "dreams_clear_keywords"].contains($0.name) }
        }
        let availableTools = tools
        await server.withMethodHandler(ListTools.self) { _ in .init(tools: availableTools) }
        await server.withMethodHandler(CallTool.self) { parameters in
            do {
                guard availableTools.contains(where: { $0.name == parameters.name }) else {
                    throw MCPError.invalidParams("Tool unavailable in this connection mode.")
                }
                switch parameters.name {
                case "dreams_publish_keywords":
                    guard case .array(let values) = parameters.arguments?["keywords"] else {
                        throw MCPError.invalidParams("keywords must be an array of strings.")
                    }
                    let words = try values.map { value -> String in
                        guard case .string(let word) = value else { throw MCPError.invalidParams("Each keyword must be a string.") }
                        return word
                    }
                    let activity = try parameters.arguments?["activity"].map { try string($0) } ?? "working"
                    guard let state = KeywordMessage.Activity(rawValue: activity) else {
                        throw MCPError.invalidParams("activity must be working or idle.")
                    }
                    try KeywordFeed().publish(sessionID: string(parameters.arguments?["session_id"]), words: words,
                        color: parameters.arguments?["color"].map { try string($0) } ?? "cyan",
                        ttl: number(parameters.arguments?["ttl_seconds"], fallback: 90), activity: state)
                case "dreams_clear_keywords":
                    try KeywordFeed().clear(sessionID: string(parameters.arguments?["session_id"]))
                case "dreams_preview":
                    let png = try await controller.previewPNG()
                    return .init(content: [.image(data: png.base64EncodedString(), mimeType: "image/png", annotations: nil, _meta: nil)], isError: false)
                case "dreams_status": break
                case "dreams_start":
                    try await controller.start(
                        duration: number(parameters.arguments?["duration_seconds"], fallback: 300),
                        brightness: number(parameters.arguments?["brightness"], fallback: 0.18))
                case "dreams_stop", "dreams_prepare_ui": await controller.stop(reason: .agent)
                case "dreams_resume": try await controller.resume()
                case "dreams_workspace_create": try await controller.createWorkspace()
                case "dreams_workspace_close": await controller.closeWorkspace()
                default: throw MCPError.invalidParams("Unknown tool: \(parameters.name)")
                }
                return .init(content: [.text(text: try await controller.statusJSON(), annotations: nil, _meta: nil)], isError: false)
            } catch {
                return .init(content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)], isError: true)
            }

    private var hotkeyButton: NSButton?
    private var hotkeyNote: NSTextField?
    private var hotkeyMonitor: Any?
    private var stopMenuItem: NSMenuItem?
    private var hookStatusLabels: [String: NSTextField] = [:]
    private var hookButtons: [String: NSButton] = [:]
    private var glowSlider: NSSlider?
    private var rainColorWell: NSColorWell?
    /// The settings controls by accessibility identifier, so a reset can bring them all up to date.
    private var controlsByID: [String: NSControl] = [:]
    private let speedLabel = NSTextField(labelWithString: "")
    private let brightnessSpreadLabel = NSTextField(labelWithString: "")
    let controller = DreamsController()
    var showsControls = false
    private var controlsWindow: DreamsControlsWindow?
    private var activityLabel: NSTextField?
    private var activityTimer: Timer?
    private var statusItem: NSStatusItem?
    private let emergencyHotkey = EmergencyHotkey()

    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        if showsControls { showControls() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if showsControls { showControls() }
        return true
    }

    @objc private func showControls() {
        if controlsWindow == nil {
            let window = DreamsControlsWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 600),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Dreams"
            window.isReleasedWhenClosed = false
            window.onEscape = { [weak self] in self?.controller.handleEscape() }

            // Header: status and the main actions.
            let activityLabel = NSTextField(wrappingLabelWithString: "")
            activityLabel.textColor = .secondaryLabelColor
            activityLabel.preferredMaxLayoutWidth = 420

            let needed = stack.fittingSize.height + 32
            let available = (NSScreen.main?.visibleFrame.height ?? 900) - 80
            window.setContentSize(NSSize(width: 460, height: min(needed, available)))
            content.layoutSubtreeIfNeeded()
            if stack.frame.height + 32 > window.contentLayoutRect.height, needed < available {
                window.setContentSize(NSSize(width: 460, height: min(stack.frame.height + 32, available)))
            }
            window.center()
            controlsWindow = window
            refreshActivityLabel()
            activityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshActivityLabel() }
            }
        }
        controller.stopForReopen()
        NSApplication.shared.activate(ignoringOtherApps: true)
        controlsWindow?.makeKeyAndOrderFront(nil)
    }

    /// Debug actions: the settings window's right-click menu and the status item's Debug submenu.
    private func debugMenu() -> NSMenu {

            ? (controller.rainIdleIntensity > 0
                ? L("activity.waiting")
                : L("activity.waitingOff"))
            : L("activity.working", count, Int(KeywordMessage.workLevel(messages) * 100))
        activityLabel?.stringValue = activity + "\n" + controller.animationStatus
    }

    func setupMenu() {
        controller.emergencyHotkeyRegistered = emergencyHotkey.install(controller: controller, hotkey: controller.stopHotkey)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let icon = StatusIcon.image() {
            item.button?.image = icon
        } else {
            item.button?.title = "◒"
        }
        item.button?.setAccessibilityLabel("Dreams")
        let menu = NSMenu()
        if showsControls {
            menu.addItem(withTitle: L("menu.openControls"), action: #selector(showControls), keyEquivalent: "")
            menu.addItem(.separator())
        }
        menu.addItem(withTitle: L("menu.startMatrix"), action: #selector(start), keyEquivalent: "")
        let stopItem = menu.addItem(withTitle: L("menu.stop"), action: #selector(stop), keyEquivalent: "")
        stopMenuItem = stopItem
        refreshStopMenuItem()
        menu.addItem(.separator())
        let debug = menu.addItem(withTitle: L("debug.menu"), action: nil, keyEquivalent: "")
        debug.submenu = debugMenu()
        menu.addItem(.separator())
        menu.addItem(withTitle: L("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        for menuItem in menu.items where menuItem.submenu == nil { menuItem.target = self }

        stopMenuItem?.keyEquivalentModifierMask = equivalent?.flags ?? []
    }

    /// Records the next ⌃/⌥/⌘ key combination as the stop shortcut; Esc or a second click cancels.
    @objc private func recordHotkey(_ sender: NSButton) {
        if let monitor = hotkeyMonitor { NSEvent.removeMonitor(monitor); hotkeyMonitor = nil; refreshRunTimeHint(); return }
        sender.title = L("hotkey.recording")
        hotkeyNote?.stringValue = ""
        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if Int(event.keyCode) == kVK_Escape {
                self.finishRecording(with: nil)
            } else if let hotkey = StopHotkey(event: event) {
                self.finishRecording(with: hotkey)
            } else {
                NSSound.beep()  // not usable: needs ⌃, ⌥ or ⌘
            }
            return nil
        }
    }

    private func finishRecording(with hotkey: StopHotkey?) {
        if let monitor = hotkeyMonitor { NSEvent.removeMonitor(monitor); hotkeyMonitor = nil }
        if let hotkey, hotkey != controller.stopHotkey { applyStopHotkey(hotkey) }
        refreshRunTimeHint()
    }

    @objc private func resetHotkey() {
        if let monitor = hotkeyMonitor { NSEvent.removeMonitor(monitor); hotkeyMonitor = nil }
        applyStopHotkey(.standard)
        refreshRunTimeHint()
    }

    private func applyStopHotkey(_ hotkey: StopHotkey) {
        if emergencyHotkey.change(to: hotkey) {
            controller.stopHotkey = hotkey
            controller.emergencyHotkeyRegistered = true
            hotkeyNote?.stringValue = ""
        } else {
            hotkeyNote?.stringValue = L("hotkey.taken", hotkey.display)
        }
        refreshStopMenuItem()
    }


        refreshValueLabels()
    }

    @objc private func showFixtures() {
        do { try controller.showEventFixtures() } catch { show(error: error) }
    }

    @objc private func start() { do { try controller.startWithRunTime() } catch { show(error: error) } }
    @objc private func stop() { controller.stop() }
    @objc private func workspace() {
        Task { do { try await controller.createWorkspace() } catch { show(error: error) } }
    }
    @objc private func closeWorkspace() { controller.closeWorkspace() }
    @objc private func quit() { NSApplication.shared.terminate(nil) }

    func applicationWillTerminate(_ notification: Foundation.Notification) {
        activityTimer?.invalidate()
        emergencyHotkey.uninstall()
        controller.cleanUp()
    }
    func show(error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}

@MainActor
private final class DreamsControlsWindow: NSWindow {
    var onEscape: (() -> Void)?
    override func cancelOperation(_ sender: Any?) { onEscape?() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?() }
        else { super.keyDown(with: event) }
    }
}
