import AppKit
import Carbon.HIToolbox

@MainActor
final class DreamsSettingsDocumentView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
final class SettingsPageController: NSObject {
    let columnsLabel = NSTextField(labelWithString: "")
    let densityLabel = NSTextField(labelWithString: "")
    let fadeLabel = NSTextField(labelWithString: "")
    let keywordBrightnessLabel = NSTextField(labelWithString: "")
    let idleLabel = NSTextField(labelWithString: "")
    let glowLabel = NSTextField(labelWithString: "")
    var runTimeHint: NSTextField?
    var hotkeyButton: NSButton?
    var hotkeyNote: NSTextField?
    var hotkeyMonitor: Any?
    var hookStatusLabels: [String: NSTextField] = [:]
    var hookButtons: [String: NSButton] = [:]
    var glowSlider: NSSlider?
    var rainColorWell: NSColorWell?
    /// The settings controls by accessibility identifier, so a reset can bring them all up to date.
    var controlsByID: [String: NSControl] = [:]
    let speedLabel = NSTextField(labelWithString: "")
    let brightnessSpreadLabel = NSTextField(labelWithString: "")
    let controller: DreamsController
    var onHotkeyChange: (() -> Void)?

    init(controller: DreamsController) {
        self.controller = controller
        super.init()
    }
    var controlsWindow: DreamsControlsWindow?
    var activityLabel: NSTextField?
    var activityTimer: Timer?
    var focusObserver: NSObjectProtocol?
    let emergencyHotkey = EmergencyHotkey()

    /// Debug actions: the settings window's right-click menu and the status item's Debug submenu.
    func debugMenu() -> NSMenu {
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

    func refreshValueLabels() {
        columnsLabel.stringValue = String(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount)
        (controlsByID["dreams.rain-columns"] as? NSSlider)?.isEnabled = controller.rainColumnCount != 0
        densityLabel.stringValue = "\(Int((controller.rainDensity * 100).rounded()))%"
        speedLabel.stringValue = String(format: "%.2f×", controller.rainSpeed)
        fadeLabel.stringValue = L("rain.fade.value", Int(controller.rainFadeRows))
        brightnessSpreadLabel.stringValue = "\(Int((controller.rainBrightnessSpread * 100).rounded()))%"
        glowLabel.stringValue = "\(Int((controller.rainGlow * 100).rounded()))%"
        idleLabel.stringValue = "\(Int((controller.rainIdleIntensity * 100).rounded()))%"
        keywordBrightnessLabel.stringValue = "\(Int((controller.keywordBrightness * 100).rounded()))%"
    }

    func refreshActivityLabel() {
        guard let messages = try? KeywordFeed().snapshot() else { return }
        let count = messages.filter(\.isWorking).count
        let activity = count == 0
            ? (controller.rainIdleIntensity > 0
                ? L("activity.waiting")
                : L("activity.waitingOff"))
            : L("activity.working", count, Int(KeywordMessage.workLevel(messages) * 100))
        activityLabel?.stringValue = activity + "\n" + controller.animationStatus
    }

    func installShortcuts() {
        controller.emergencyHotkeyRegistered = emergencyHotkey.install(controller: controller, hotkey: controller.stopHotkey)
    }

    @objc func changeFade(_ sender: NSSlider) {
        controller.rainFadeRows = sender.doubleValue.rounded()
        refreshValueLabels()
    }

    @objc func changeTransparency(_ sender: NSButton) {
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

    func refreshHooks() {
        for (source, _) in HooksInstaller.targets {
            let state = HooksInstaller.state(source: source)
            let statusKey: String
            switch state {
            case .connected: statusKey = "hooks.state.connected"
            case .outdated: statusKey = "hooks.state.outdated"
            case .plugin: statusKey = "hooks.state.plugin"
            case .duplicate: statusKey = "hooks.state.duplicate"
            case .notConnected: statusKey = "hooks.state.notConnected"
            }
            hookStatusLabels[source]?.stringValue = L(statusKey)
            hookStatusLabels[source]?.toolTip = Bundle.main.executablePath.map { L("hooks.path.tip", $0) }
            hookButtons[source]?.title = L(state == .connected ? "button.disconnect"
                : state == .outdated ? "button.update" : state == .duplicate ? "button.removeDuplicate"
                : state == .plugin ? "button.plugin" : "button.connect")
            // With the plugin there is nothing to connect here: it is managed by the agent's plugin commands.
            hookButtons[source]?.isEnabled = state != .plugin
        }
    }

    @objc func toggleHooks(_ sender: NSButton) {
        guard let source = sender.identifier?.rawValue else { return }
        let state = HooksInstaller.state(source: source)
        let connected = state == .connected || state == .duplicate
        do { _ = try HooksInstaller.run(uninstall: connected, dryRun: false, only: [source]) }
        catch { show(error: error) }
        refreshHooks()
    }

    static func runTimeTitle(_ seconds: Double) -> String {
        switch seconds {
        case 300: return L("runtime.5m")
        case 1800: return L("runtime.30m")
        case 3600: return L("runtime.1h")
        default: return L("runtime.unlimited")
        }
    }

    func refreshRunTimeHint() {
        let seconds = controller.runTimeSeconds
        (controlsByID["dreams.run-time"] as? NSPopUpButton)?.isEnabled = !controller.transparentBackground
        let hotkey = controller.stopHotkey.display
        runTimeHint?.stringValue = controller.transparentBackground ? L("hint.runtime.transparent", hotkey)
            : seconds > 0 ? L("hint.runtime", Self.runTimeTitle(seconds).lowercased(), hotkey)
            : L("hint.runtime.unlimited", hotkey)
        hotkeyButton?.title = controller.stopHotkey.display
    }

    /// Records the next ⌃/⌥/⌘ key combination as the stop shortcut; Esc or a second click cancels.
    @objc func recordHotkey(_ sender: NSButton) {
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

    func finishRecording(with hotkey: StopHotkey?) {
        if let monitor = hotkeyMonitor { NSEvent.removeMonitor(monitor); hotkeyMonitor = nil }
        if let hotkey, hotkey != controller.stopHotkey { applyStopHotkey(hotkey) }
        refreshRunTimeHint()
    }

    @objc func resetHotkey() {
        if let monitor = hotkeyMonitor { NSEvent.removeMonitor(monitor); hotkeyMonitor = nil }
        applyStopHotkey(.standard)
        refreshRunTimeHint()
    }

    func applyStopHotkey(_ hotkey: StopHotkey) {
        if emergencyHotkey.change(to: hotkey) {
            controller.stopHotkey = hotkey
            controller.emergencyHotkeyRegistered = true
            hotkeyNote?.stringValue = ""
        } else {
            hotkeyNote?.stringValue = L("hotkey.taken", hotkey.display)
        }
        onHotkeyChange?()
    }

    @objc func changeRunTime(_ sender: NSPopUpButton) {
        guard let seconds = sender.selectedItem?.representedObject as? Double else { return }
        controller.runTimeSeconds = seconds
        refreshRunTimeHint()
    }

    @objc func resetDefaults() {
        let alert = NSAlert()
        alert.messageText = L("reset.confirm.title")
        alert.informativeText = L("reset.confirm.text")
        alert.addButton(withTitle: L("reset.confirm.action"))
        alert.addButton(withTitle: L("button.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { try controller.resetToDefaults() } catch { show(error: error) }
        applyStopHotkey(controller.stopHotkey)
        syncControls()
    }

    /// Brings every control up to date with the controller (after a reset).
    func syncControls() {
        func slider(_ id: String, _ value: Double) { (controlsByID[id] as? NSSlider)?.doubleValue = value }
        slider("dreams.rain-columns", Double(controller.rainColumnCount == 0
            ? controller.automaticColumnCount : controller.rainColumnCount))
        (controlsByID["dreams.rain-columns-auto"] as? NSButton)?.state = controller.rainColumnCount == 0 ? .on : .off
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

    @objc func changeHideFromScreenshots(_ sender: NSButton) {
        controller.setHideFromScreenshots(sender.state == .on)
    }

    @objc func changeGlyphSet(_ sender: NSButton) {
        do { try controller.setRestoredGlyphs(sender.state == .on) }
        catch {
            sender.state = controller.restoredGlyphs ? .on : .off
            show(error: error)
        }
    }

    @objc func changeRainColor(_ sender: NSColorWell) {
        controller.rainColor = sender.color
    }

    @objc func changeKeywordColor(_ sender: NSColorWell) {
        controller.keywordColor = sender.color
    }

    @objc func changeKeywordBrightness(_ sender: NSSlider) {
        controller.keywordBrightness = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeIdle(_ sender: NSSlider) {
        controller.rainIdleIntensity = sender.doubleValue
        refreshValueLabels()
        refreshActivityLabel()
    }

    @objc func changeGlow(_ sender: NSSlider) {
        controller.rainGlow = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeSpeed(_ sender: NSSlider) {
        controller.rainSpeed = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeBrightnessSpread(_ sender: NSSlider) {
        controller.rainBrightnessSpread = sender.doubleValue
        refreshValueLabels()
    }

    @objc func changeAutomaticColumns(_ sender: NSButton) {
        controller.rainColumnCount = sender.state == .on ? 0 : min(240, max(24, controller.automaticColumnCount))
        syncControls()
    }

    @objc func changeColumns(_ sender: NSSlider) {
        controller.rainColumnCount = Int(sender.doubleValue.rounded())
        sender.doubleValue = Double(controller.rainColumnCount)
        refreshValueLabels()
    }

    @objc func changeDensity(_ sender: NSSlider) {
        controller.rainDensity = sender.doubleValue
        refreshValueLabels()
    }

    @objc func showFixtures() {
        do { try controller.showEventFixtures() } catch { show(error: error) }
    }

    @objc func start() { do { try controller.startWithRunTime() } catch { show(error: error) } }
    @objc func stop() { controller.stop() }
    @objc func workspace() {
        Task { do { try await controller.createWorkspace() } catch { show(error: error) } }
    }
    @objc func closeWorkspace() { controller.closeWorkspace() }
    @objc func quit() { NSApplication.shared.terminate(nil) }

    func cleanUp() {
        activityTimer?.invalidate()
        if let focusObserver {
            NotificationCenter.default.removeObserver(focusObserver)
            self.focusObserver = nil
        }
        if let hotkeyMonitor { NSEvent.removeMonitor(hotkeyMonitor); self.hotkeyMonitor = nil }
        emergencyHotkey.uninstall()
        controller.cleanUp()
    }
    func show(error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}

@MainActor
final class DreamsControlsWindow: NSWindow {
    var onEscape: (() -> Void)?
    override func cancelOperation(_ sender: Any?) { onEscape?() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?() }
        else { super.keyDown(with: event) }
    }
}
