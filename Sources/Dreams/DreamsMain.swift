import AppKit
import MetalKit
import MCP

@main
enum DreamsMain {
    @MainActor
    static func main() {
        if let hookIndex = CommandLine.arguments.firstIndex(of: "--hook") {
            guard CommandLine.arguments.indices.contains(hookIndex + 1) else { return }
            KeywordInput.runHook(source: CommandLine.arguments[hookIndex + 1])
            return
        }
        if CommandLine.arguments.contains("--install-hooks") || CommandLine.arguments.contains("--uninstall-hooks") {
            do {
                let lines = try HooksInstaller.run(uninstall: CommandLine.arguments.contains("--uninstall-hooks"),
                                                   dryRun: CommandLine.arguments.contains("--dry-run"))
                print(lines.joined(separator: "\n"))
            } catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        if CommandLine.arguments.contains("--hooks-status") {
            for (source, _) in HooksInstaller.targets {
                print("\(source): \(HooksInstaller.state(source: source).rawValue)")
            }
            return
        }
        if CommandLine.arguments.contains("--fixture-events") {
            do { try KeywordInput.publishFixtures() }
            catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        if CommandLine.arguments.contains("--publish") {
            do { try KeywordInput.runPublish() }
            catch {
                FileHandle.standardError.write(Data("Dreams: \(error.localizedDescription)\n".utf8))
                exit(1)
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
                        throw DreamsError.unavailable("--render-demo requires an output directory.")
                    }
                    let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    let renderer = try RainRenderer(view: MTKView(frame: .zero))
                    let activityDemo = CommandLine.arguments.contains("--activity-demo")
                    for frame in 0..<(activityDemo ? 480 : 180) {
                        renderer.demoWorkingAgents = activityDemo
                            ? (frame < 120 ? 3 : frame < 180 ? 1 : frame < 330 ? 0 : 2) : 3
                        let data = try await renderer.previewPNG(posedTime: Float(frame) / 30)
                        try data.write(to: directory.appendingPathComponent(String(format: "%04d.png", frame)))
                    }
                } catch {
                    FileHandle.standardError.write(Data("Dreams render: \(error)\n".utf8))
                    exit(1)
                }
                application.terminate(nil)
            }
        } else if CommandLine.arguments.contains("--lab") {
            Task {
                do { try await delegate.controller.createWorkspace() }
                catch { delegate.show(error: error) }
            }
        }
        withExtendedLifetime(delegate) { application.run() }
    }

    static func runServer(controller: DreamsController, publisherOnly: Bool) async throws {
        let server = Server(name: "dreams", version: "0.2.0", instructions: """
            You control the user's Dreams screen animation. Call dreams_prepare_ui BEFORE taking
            screenshots or sending input to the built-in desktop, then dreams_resume after UI work.
            The rain may stay visible while using a separately captured virtual-display window only
            after verifying that your UI tool captures and clicks that window correctly.
            Creating a virtual display does not automatically redirect your computer-use tools.
            Publish short public task labels with dreams_publish_keywords at meaningful milestones.
            Use a unique session_id. These labels are visible on the user's screen; send only words
            intended for display. Publishing never opens the overlay. Hooks can provide automatic
            activity labels while MCP can provide more specific topics.
            """, capabilities: .init(tools: .init()))
        let emptySchema: Value = .object(["type": "object", "properties": .object([:]),
                                          "additionalProperties": false])
        var tools: [Tool] = [
            Tool(name: "dreams_publish_keywords", description: "Replace this session's public task keywords. They appear vertically, one letter per row, inside active Matrix rain. Accepts 1...6 short words/phrases, expires after ttl_seconds (15...300, default 90). Does not open or focus any window.", inputSchema: .object([
                "type": "object", "required": ["session_id", "keywords"],
                "properties": .object([
                    "session_id": .object(["type": "string", "minLength": 1, "maxLength": 192]),
                    "keywords": .object(["type": "array", "minItems": 1, "maxItems": 6,
                        "items": .object(["type": "string", "minLength": 1, "maxLength": 32])]),
                    "color": .object(["type": "string", "enum": .array(KeywordMessage.colors.map { .string($0) })]),
                    "ttl_seconds": .object(["type": "number", "minimum": 15, "maximum": 300]),
                    "activity": .object(["type": "string", "enum": ["working", "idle"]])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_clear_keywords", description: "Remove only the public keywords for the given session_id.", inputSchema: .object([
                "type": "object", "required": ["session_id"], "properties": .object([
                    "session_id": .object(["type": "string", "minLength": 1, "maxLength": 192])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_status", description: "Read rain, settings and virtual workspace state, display IDs, bounds and test click count.", inputSchema: emptySchema),
            Tool(name: "dreams_preview", description: "Render the rain and keyword feed to a PNG without capturing the screen. Does not show or hide the overlay.", inputSchema: emptySchema),
            Tool(name: "dreams_start", description: "Show Matrix rain on the built-in display. Covers screenshots of that display. Use prepare_ui before ordinary desktop computer use. Auto-stops after duration_seconds (default 300, maximum 3600).", inputSchema: .object([
                "type": "object", "properties": .object([
                    "duration_seconds": .object(["type": "number", "minimum": 1, "maximum": 3600]),
                    "brightness": .object(["type": "number", "minimum": 0.02, "maximum": 0.35])
                ]), "additionalProperties": false
            ])),
            Tool(name: "dreams_stop", description: "Remove the rain immediately and release the display sleep assertion. Does not destroy the virtual workspace.", inputSchema: emptySchema),
            Tool(name: "dreams_prepare_ui", description: "Remove the rain BEFORE screenshots, clicks or keyboard actions on the built-in desktop. The screen is unprotected during UI work. Resume afterward.", inputSchema: emptySchema),
            Tool(name: "dreams_resume", description: "Resume the rain using the last brightness and duration after UI work.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_create", description: "EXPERIMENTAL: create a separate virtual display using a private macOS API and show a harmless Increment test window. Does not move existing apps or guarantee native agent compatibility.", inputSchema: emptySchema),
            Tool(name: "dreams_workspace_close", description: "Close the test window and disconnect only the virtual display owned by this Dreams process. Other windows placed on it may move to a physical display.", inputSchema: emptySchema)
        ]
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
        }
        try await server.start(transport: CodexCompatibleStdioTransport())
        await server.waitUntilCompleted()
    }

    private static func string(_ value: Value?) throws -> String {
        guard case .string(let text) = value else { throw MCPError.invalidParams("Expected a string argument.") }
        return text
    }

    private static func number(_ value: Value?, fallback: Double) throws -> Double {
        guard let value else { return fallback }
        switch value {
        case .double(let number): return number
        case .int(let number): return Double(number)
        default: throw MCPError.invalidParams("Expected a numeric argument.")
        }
    }
}

@MainActor
final class DreamsSettingsDocumentView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
final class DreamsDelegate: NSObject, NSApplicationDelegate {
    private let densityLabel = NSTextField(labelWithString: "")
    private let fadeLabel = NSTextField(labelWithString: "")
    private let keywordBrightnessLabel = NSTextField(labelWithString: "")
    private let idleLabel = NSTextField(labelWithString: "")
    private let glowLabel = NSTextField(labelWithString: "")
    private var runTimeHint: NSTextField?
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
            window.onEscape = { [weak self] in self?.controller.stop(reason: .escape) }

            // Header: status and the main actions.
            let activityLabel = NSTextField(wrappingLabelWithString: "")
            activityLabel.textColor = .secondaryLabelColor
            activityLabel.preferredMaxLayoutWidth = 420
            self.activityLabel = activityLabel
            let matrix = NSButton(title: L("button.startMatrix"), target: self, action: #selector(start))
            matrix.setAccessibilityIdentifier("dreams.start-matrix")
            matrix.keyEquivalent = "\r"
            let stopButton = NSButton(title: L("button.stop"), target: self, action: #selector(stop))
            stopButton.setAccessibilityIdentifier("dreams.stop")
            let runTime = NSPopUpButton(frame: .zero, pullsDown: false)
            for seconds in DreamsPreset.runTimeChoices {
                runTime.addItem(withTitle: Self.runTimeTitle(seconds))
                runTime.lastItem?.representedObject = seconds
            }
            runTime.selectItem(at: DreamsPreset.runTimeChoices.firstIndex(of: controller.runTimeSeconds) ?? 2)
            runTime.target = self
            runTime.action = #selector(changeRunTime(_:))
            runTime.toolTip = L("runtime.tip")
            runTime.setAccessibilityLabel(L("runtime.accessibility"))
            runTime.setAccessibilityIdentifier("dreams.run-time")
            controlsByID["dreams.run-time"] = runTime
            let launch = NSStackView(views: [matrix, stopButton, runTime])
            launch.spacing = 8
            let escapeHint = Self.note("")
            runTimeHint = escapeHint
            refreshRunTimeHint()

            // Rain.
            let rainColor = NSColorWell()
            rainColor.color = controller.rainColor
            rainColor.target = self
            rainColor.action = #selector(changeRainColor(_:))
            rainColor.setAccessibilityLabel(L("rain.color.accessibility"))
            rainColor.setAccessibilityIdentifier("dreams.rain-color")
            rainColor.toolTip = L("rain.color.tip")
            rainColorWell = rainColor
            controlsByID["dreams.rain-color"] = rainColor
            let rain = settingsGrid([
                [Self.name(L("label.color")), rainColor, NSView()],
                sliderRow(L("rain.density"), value: controller.rainDensity, min: 0, max: 1,
                          action: #selector(changeDensity(_:)), valueLabel: densityLabel,
                          identifier: "dreams.rain-density",
                          tip: L("rain.density.tip")),
                sliderRow(L("rain.speed"), value: controller.rainSpeed, min: 0.25, max: 3,
                          action: #selector(changeSpeed(_:)), valueLabel: speedLabel,
                          identifier: "dreams.rain-speed", tip: L("rain.speed.tip")),
                sliderRow(L("rain.fade"), value: controller.rainFadeRows, min: 1, max: 16,
                          action: #selector(changeFade(_:)), valueLabel: fadeLabel, ticks: 16,
                          identifier: "dreams.rain-fade",
                          tip: L("rain.fade.tip")),
                sliderRow(L("rain.spread"), value: controller.rainBrightnessSpread, min: 0, max: 1,
                          action: #selector(changeBrightnessSpread(_:)), valueLabel: brightnessSpreadLabel,
                          identifier: "dreams.rain-brightness-spread",
                          tip: L("rain.spread.tip")),
                sliderRow(L("rain.glow"), value: controller.rainGlow, min: 0, max: 3,
                          action: #selector(changeGlow(_:)), valueLabel: glowLabel,
                          identifier: "dreams.rain-glow",
                          tip: L("rain.glow.tip")),
            ])
            glowSlider = rain.cell(atColumnIndex: 1, rowIndex: 5).contentView as? NSSlider

            // Background between agent messages.
            let background = settingsGrid([
                sliderRow(L("rain.idle"), value: controller.rainIdleIntensity, min: 0, max: 1,
                          action: #selector(changeIdle(_:)), valueLabel: idleLabel,
                          identifier: "dreams.rain-idle",
                          tip: L("rain.idle.tip")),
            ])
            let transparent = NSButton(checkboxWithTitle: L("check.transparent"),
                target: self, action: #selector(changeTransparency(_:)))
            transparent.state = controller.transparentBackground ? .on : .off
            transparent.setAccessibilityIdentifier("dreams.transparent-background")
            controlsByID["dreams.transparent-background"] = transparent

            let screenshots = NSButton(checkboxWithTitle: L("check.hideFromScreenshots"),
                target: self, action: #selector(changeHideFromScreenshots(_:)))
            screenshots.state = controller.hideFromScreenshots ? .on : .off
            screenshots.toolTip = L("check.hideFromScreenshots.tip")
            screenshots.setAccessibilityIdentifier("dreams.hide-from-screenshots")
            controlsByID["dreams.hide-from-screenshots"] = screenshots

            // Agent words and call lines.
            let wordColor = NSColorWell()
            wordColor.color = controller.keywordColor
            wordColor.target = self
            wordColor.action = #selector(changeKeywordColor(_:))
            wordColor.setAccessibilityLabel(L("words.color.accessibility"))
            wordColor.setAccessibilityIdentifier("dreams.keyword-color")
            controlsByID["dreams.keyword-color"] = wordColor
            let words = settingsGrid([
                [Self.name(L("label.color")), wordColor, NSView()],
                sliderRow(L("words.brightness"), value: controller.keywordBrightness, min: 0, max: 2,
                          action: #selector(changeKeywordBrightness(_:)), valueLabel: keywordBrightnessLabel,
                          identifier: "dreams.keyword-brightness", tip: L("words.brightness.tip")),
            ])

            // Agent hooks: connect Dreams to Codex and Claude Code.
            let hooksGrid = NSGridView(views: HooksInstaller.targets.map { source, _ in
                let name = Self.name(L("hooks." + source))
                let status = NSTextField(labelWithString: "")
                status.textColor = .secondaryLabelColor
                let button = NSButton(title: L("button.connect"), target: self, action: #selector(toggleHooks(_:)))
                button.identifier = NSUserInterfaceItemIdentifier(source)
                button.setAccessibilityIdentifier("dreams.hooks-" + source)
                hookStatusLabels[source] = status
                hookButtons[source] = button
                return [name, status, button]
            })
            hooksGrid.rowSpacing = 6
            hooksGrid.columnSpacing = 12
            hooksGrid.column(at: 0).width = 120
            hooksGrid.column(at: 1).width = 170
            hooksGrid.column(at: 2).width = 110
            hooksGrid.column(at: 2).xPlacement = .trailing
            for index in 0..<hooksGrid.numberOfRows { hooksGrid.row(at: index).yPlacement = .center }
            let hooksNote = Self.note(L("hooks.note"))

            // Glyphs and the demo.
            let restored = NSButton(checkboxWithTitle: L("check.restored"),
                target: self, action: #selector(changeGlyphSet(_:)))
            restored.state = controller.restoredGlyphs ? .on : .off
            restored.setAccessibilityIdentifier("dreams.restored-glyphs")
            controlsByID["dreams.restored-glyphs"] = restored
            let quitButton = NSButton(title: L("button.quit"), target: self, action: #selector(quit))
            let resetButton = NSButton(title: L("button.reset"), target: self, action: #selector(resetDefaults))
            resetButton.setAccessibilityIdentifier("dreams.reset-defaults")
            resetButton.toolTip = L("button.reset.tip")
            let spacer = NSView()
            spacer.setContentHuggingPriority(.init(1), for: .horizontal)
            let footer = NSStackView(views: [resetButton, spacer, quitButton])
            footer.orientation = .horizontal
            footer.widthAnchor.constraint(equalToConstant: 420).isActive = true

            let stack = NSStackView(views: [
                activityLabel, launch, escapeHint,
                Self.section(L("section.rain")), rain,
                Self.section(L("section.between")), background, transparent, screenshots,
                Self.section(L("section.words")), words,
                Self.section(L("section.agents")), hooksGrid, hooksNote,
                Self.section(L("section.glyphs")), restored,
                Self.separator(), footer,
            ])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 10
            for (view, gap) in [(launch, 6.0), (escapeHint, 18.0), (rain, 18.0), (screenshots, 18.0),
                                (words, 18.0), (hooksNote, 18.0), (restored, 14.0)] as [(NSView, CGFloat)] {
                stack.setCustomSpacing(gap, after: view)
            }
            stack.translatesAutoresizingMaskIntoConstraints = false
            refreshValueLabels()
            refreshHooks()
            NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window,
                                                   queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshHooks() }
            }
            let content = window.contentView!
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.autohidesScrollers = true
            scroll.drawsBackground = false
            scroll.translatesAutoresizingMaskIntoConstraints = false
            let document = DreamsSettingsDocumentView()
            document.translatesAutoresizingMaskIntoConstraints = false
            // Debug tools live in the right-click menu, out of the everyday settings.
            document.menu = debugMenu()
            scroll.documentView = document
            content.addSubview(scroll)
            document.addSubview(stack)
            NSLayoutConstraint.activate([
                scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                scroll.topAnchor.constraint(equalTo: content.topAnchor),
                scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor),
                document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
                stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -20),
                stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 16),
                stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -16)
            ])
            // Size the window to its laid-out content (16 pt margins above and below);
            // scroll only on very small screens. The status text must be in place first:
            // an empty status label would measure one line short.
            refreshActivityLabel()
            content.layoutSubtreeIfNeeded()
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
        let menu = NSMenu(title: L("debug.menu"))
        let fixtures = menu.addItem(withTitle: L("debug.fixtures"), action: #selector(showFixtures), keyEquivalent: "")
        fixtures.target = self
        fixtures.toolTip = L("debug.fixtures.tip")
        fixtures.setAccessibilityIdentifier("dreams.event-fixtures")
        menu.addItem(.separator())
        // An experiment (a virtual display through a private API) that agents use through MCP.
        let create = menu.addItem(withTitle: L("menu.workspaceCreate"), action: #selector(workspace), keyEquivalent: "")
        let close = menu.addItem(withTitle: L("menu.workspaceClose"), action: #selector(closeWorkspace), keyEquivalent: "")
        for item in [create, close] { item.target = self }
        return menu
    }

    private static func name(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
    }

    private static func note(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = 420
        return label
    }

    private static func section(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private static func separator() -> NSBox {
        let line = NSBox()
        line.boxType = .separator
        line.widthAnchor.constraint(equalToConstant: 420).isActive = true
        return line
    }

    /// One settings row: name · slider · value. The hint lives in tooltips, not on screen.
    private func sliderRow(_ title: String, value: Double, min: Double, max: Double, action: Selector,
                           valueLabel: NSTextField, ticks: Int = 0, identifier: String, tip: String) -> [NSView] {
        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: self, action: action)
        slider.isContinuous = true
        if ticks > 0 {
            slider.numberOfTickMarks = ticks
            slider.allowsTickMarkValuesOnly = true
        }
        slider.setAccessibilityLabel(title)
        slider.setAccessibilityIdentifier(identifier)
        controlsByID[identifier] = slider
        slider.toolTip = tip
        let label = Self.name(title)
        label.toolTip = tip
        valueLabel.alignment = .right
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return [label, slider, valueLabel]
    }

    /// Fixed column widths keep the rows of every section aligned with each other.
    private func settingsGrid(_ rows: [[NSView]]) -> NSGridView {
        let grid = NSGridView(views: rows)
        grid.rowSpacing = 6
        grid.columnSpacing = 12
        grid.column(at: 0).width = 120
        grid.column(at: 1).width = 220
        grid.column(at: 2).width = 64
        grid.column(at: 2).xPlacement = .trailing
        for index in 0..<grid.numberOfRows { grid.row(at: index).yPlacement = .center }
        return grid
    }

    private func refreshValueLabels() {
        densityLabel.stringValue = "\(Int((controller.rainDensity * 100).rounded()))%"
        speedLabel.stringValue = String(format: "%.2f×", controller.rainSpeed)
        fadeLabel.stringValue = L("rain.fade.value", Int(controller.rainFadeRows))
        brightnessSpreadLabel.stringValue = "\(Int((controller.rainBrightnessSpread * 100).rounded()))%"
        glowLabel.stringValue = "\(Int((controller.rainGlow * 100).rounded()))%"
        idleLabel.stringValue = "\(Int((controller.rainIdleIntensity * 100).rounded()))%"
        keywordBrightnessLabel.stringValue = "\(Int((controller.keywordBrightness * 100).rounded()))%"
    }

    private func refreshActivityLabel() {
        guard let messages = try? KeywordFeed().snapshot() else { return }
        let count = messages.filter(\.isWorking).count
        let activity = count == 0
            ? (controller.rainIdleIntensity > 0
                ? L("activity.waiting")
                : L("activity.waitingOff"))
            : L("activity.working", count, Int(KeywordMessage.workLevel(messages) * 100))
        activityLabel?.stringValue = activity + "\n" + controller.animationStatus
    }

    func setupMenu() {
        controller.emergencyHotkeyRegistered = emergencyHotkey.install(controller: controller)
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
        let stopItem = menu.addItem(withTitle: L("menu.stop"), action: #selector(stop), keyEquivalent: "d")
        stopItem.keyEquivalentModifierMask = [.control, .option, .command]
        menu.addItem(.separator())
        let debug = menu.addItem(withTitle: L("debug.menu"), action: nil, keyEquivalent: "")
        debug.submenu = debugMenu()
        menu.addItem(.separator())
        menu.addItem(withTitle: L("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        for menuItem in menu.items where menuItem.submenu == nil { menuItem.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func changeFade(_ sender: NSSlider) {
        controller.rainFadeRows = sender.doubleValue.rounded()
        refreshValueLabels()
    }

    @objc private func changeTransparency(_ sender: NSButton) {
        do { try controller.setTransparentBackground(sender.state == .on) }
        catch {
            sender.state = controller.transparentBackground ? .on : .off
            show(error: error)
        }
        // Each background keeps its own glow strength and rain colour.
        glowSlider?.doubleValue = controller.rainGlow
        rainColorWell?.color = controller.rainColor
        refreshValueLabels()
        refreshRunTimeHint()
    }

    private func refreshHooks() {
        for (source, _) in HooksInstaller.targets {
            let state = HooksInstaller.state(source: source)
            hookStatusLabels[source]?.stringValue = L(state == .connected ? "hooks.state.connected"
                : state == .outdated ? "hooks.state.outdated" : "hooks.state.notConnected")
            hookStatusLabels[source]?.toolTip = Bundle.main.executablePath.map { L("hooks.path.tip", $0) }
            hookButtons[source]?.title = L(state == .connected ? "button.disconnect"
                : state == .outdated ? "button.update" : "button.connect")
        }
    }

    @objc private func toggleHooks(_ sender: NSButton) {
        guard let source = sender.identifier?.rawValue else { return }
        let connected = HooksInstaller.state(source: source) == .connected
        do { _ = try HooksInstaller.run(uninstall: connected, dryRun: false, only: [source]) }
        catch { show(error: error) }
        refreshHooks()
    }

    private static func runTimeTitle(_ seconds: Double) -> String {
        switch seconds {
        case 300: return L("runtime.5m")
        case 1800: return L("runtime.30m")
        case 3600: return L("runtime.1h")
        default: return L("runtime.unlimited")
        }
    }

    private func refreshRunTimeHint() {
        let seconds = controller.runTimeSeconds
        (controlsByID["dreams.run-time"] as? NSPopUpButton)?.isEnabled = !controller.transparentBackground
        runTimeHint?.stringValue = controller.transparentBackground ? L("hint.runtime.transparent")
            : seconds > 0 ? L("hint.runtime", Self.runTimeTitle(seconds).lowercased()) : L("hint.runtime.unlimited")
    }

    @objc private func changeRunTime(_ sender: NSPopUpButton) {
        guard let seconds = sender.selectedItem?.representedObject as? Double else { return }
        controller.runTimeSeconds = seconds
        refreshRunTimeHint()
    }

    @objc private func resetDefaults() {
        let alert = NSAlert()
        alert.messageText = L("reset.confirm.title")
        alert.informativeText = L("reset.confirm.text")
        alert.addButton(withTitle: L("reset.confirm.action"))
        alert.addButton(withTitle: L("button.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { try controller.resetToDefaults() } catch { show(error: error) }
        syncControls()
    }

    /// Brings every control up to date with the controller (after a reset).
    private func syncControls() {
        func slider(_ id: String, _ value: Double) { (controlsByID[id] as? NSSlider)?.doubleValue = value }
        slider("dreams.rain-density", controller.rainDensity)
        slider("dreams.rain-speed", controller.rainSpeed)
        slider("dreams.rain-fade", controller.rainFadeRows)
        slider("dreams.rain-brightness-spread", controller.rainBrightnessSpread)
        slider("dreams.rain-glow", controller.rainGlow)
        slider("dreams.rain-idle", controller.rainIdleIntensity)
        slider("dreams.keyword-brightness", controller.keywordBrightness)
        (controlsByID["dreams.rain-color"] as? NSColorWell)?.color = controller.rainColor
        (controlsByID["dreams.keyword-color"] as? NSColorWell)?.color = controller.keywordColor
        (controlsByID["dreams.transparent-background"] as? NSButton)?.state = controller.transparentBackground ? .on : .off
        (controlsByID["dreams.restored-glyphs"] as? NSButton)?.state = controller.restoredGlyphs ? .on : .off
        (controlsByID["dreams.hide-from-screenshots"] as? NSButton)?.state = controller.hideFromScreenshots ? .on : .off
        if let popup = controlsByID["dreams.run-time"] as? NSPopUpButton,
           let index = DreamsPreset.runTimeChoices.firstIndex(of: controller.runTimeSeconds) { popup.selectItem(at: index) }
        refreshRunTimeHint()
        refreshValueLabels()
    }

    @objc private func changeHideFromScreenshots(_ sender: NSButton) {
        controller.setHideFromScreenshots(sender.state == .on)
    }

    @objc private func changeGlyphSet(_ sender: NSButton) {
        do { try controller.setRestoredGlyphs(sender.state == .on) }
        catch {
            sender.state = controller.restoredGlyphs ? .on : .off
            show(error: error)
        }
    }

    @objc private func changeRainColor(_ sender: NSColorWell) {
        controller.rainColor = sender.color
    }

    @objc private func changeKeywordColor(_ sender: NSColorWell) {
        controller.keywordColor = sender.color
    }

    @objc private func changeKeywordBrightness(_ sender: NSSlider) {
        controller.keywordBrightness = sender.doubleValue
        refreshValueLabels()
    }

    @objc private func changeIdle(_ sender: NSSlider) {
        controller.rainIdleIntensity = sender.doubleValue
        refreshValueLabels()
        refreshActivityLabel()
    }

    @objc private func changeGlow(_ sender: NSSlider) {
        controller.rainGlow = sender.doubleValue
        refreshValueLabels()
    }

    @objc private func changeSpeed(_ sender: NSSlider) {
        controller.rainSpeed = sender.doubleValue
        refreshValueLabels()
    }

    @objc private func changeBrightnessSpread(_ sender: NSSlider) {
        controller.rainBrightnessSpread = sender.doubleValue
        refreshValueLabels()
    }

    @objc private func changeDensity(_ sender: NSSlider) {
        controller.rainDensity = sender.doubleValue
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
