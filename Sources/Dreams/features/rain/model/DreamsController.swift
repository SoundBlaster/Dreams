import AppKit
import os
import MetalKit
import IOKit.pwr_mgt
import VirtualDisplayBridge

@MainActor
final class DreamsController: NSObject {
    /// Transparent Matrix: a saved setting; the `--transparent` launch flag still turns it on.
    private(set) var transparentBackground = DreamsController.initialTransparent
    private static let initialTransparent = CommandLine.arguments.contains("--transparent")
        || UserDefaults.standard.bool(forKey: "transparentBackground")
    private let screenManager = RainScreenManager()
    private var rainRequested = false
    private var rainIsOn: Bool { rainRequested && !screenManager.overlays.isEmpty }
    private var overlay: NSWindow? { screenManager.orderedOverlays.first?.window }
    private var renderer: RainRenderer? { screenManager.renderers.first }
    static let settingsDidChange = Notification.Name("DreamsSettingsDidChange")

    private func settingsChanged() {
        NotificationCenter.default.post(name: Self.settingsDidChange, object: self)
    }

    static let displaysDidChange = Notification.Name("DreamsDisplaysDidChange")
    private(set) var displayError: String?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    var displays: [RainDisplay] { screenManager.displays }
    var displaySelection: RainDisplaySelection { screenManager.selection }

    func setDisplaySelection(_ selection: RainDisplaySelection) throws {
        let previous = screenManager.selection
        screenManager.selection = selection
        do { try reconcileScreens() }
        catch {
            screenManager.selection = previous
            throw error
        }
        selection.save()
        NotificationCenter.default.post(name: Self.displaysDidChange, object: self)
    }

    @objc private func screenParametersChanged() {
        if virtualDisplay == nil, let excluded = screenManager.excludedDisplayID,
           !NSScreen.screens.contains(where: { $0.displayID == excluded }) {
            screenManager.excludedDisplayID = nil
        }
        do { try reconcileScreens() }
        catch {
            displayError = error.localizedDescription
            log.error("Display update failed: \(error.localizedDescription, privacy: .public)")
        }
        NotificationCenter.default.post(name: Self.displaysDidChange, object: self)
    }

    private func reconcileScreens() throws {
        guard rainRequested else { return }
        try screenManager.reconcile(restoredGlyphs: restoredGlyphs, transparent: transparentBackground,
            hiddenFromCapture: hideFromScreenshots, suspended: suspendedForCapture, configure: configureRenderer,
            onEscape: { [weak self] in self?.handleEscape() },
            onExit: { [weak self] in self?.stop(reason: .user) })
        displayError = nil
        updateSleepAssertion()
    }

    private func updateSleepAssertion() {
        let needed = rainIsOn && (!transparentBackground || lastDuration != nil)
        if needed && !assertionActive {
            let result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn), "Dreams agent session" as CFString, &assertionID)
            assertionActive = result == kIOReturnSuccess
        } else if !needed && assertionActive {
            IOPMAssertionRelease(assertionID)
            assertionActive = false
        }
    }
    private var suspendedForCapture = false
    private var captureWatcher: Timer?
    private var captureClearSince: Date?
    private var expiryTask: Task<Void, Never>?
    private var demoTask: Task<Void, Never>?
    private var virtualDisplay: DreamsVirtualDisplay?
    private var workspaceWindow: NSWindow?
    private let counterLabel = NSTextField(labelWithString: "Clicks: 0")
    private var clicks = 0
    private var assertionID: IOPMAssertionID = 0
    private var assertionActive = false
    private var expiresAt: Date?
    private var lastDuration: Double? = 300
    /// Why the rain last stopped, shown in the window until the next start.
    enum StopReason: String { case user, escape, hotkey, reopen, timer, agent, restart }
    private let log = Logger(subsystem: "ru.egormerkushev.dreams", category: "rain")
    private(set) var lastStopReason: StopReason?

    /// Hide only the status item; native application commands and shortcuts remain available.
    var showsMenuBarIcon = UserDefaults.standard.object(forKey: "showsMenuBarIcon") as? Bool
        ?? DreamsPreset.showsMenuBarIcon {
        didSet { UserDefaults.standard.set(showsMenuBarIcon, forKey: "showsMenuBarIcon"); settingsChanged() }
    }

    var runTimeSeconds: Double = {
        let value = UserDefaults.standard.object(forKey: "runTimeSeconds") as? Double ?? DreamsPreset.runTimeSeconds
        return DreamsPreset.runTimeChoices.contains(value) ? value : DreamsPreset.runTimeSeconds
    }() {
        didSet { UserDefaults.standard.set(runTimeSeconds, forKey: "runTimeSeconds"); settingsChanged() }
    }
    private var lastBrightness = 0.18
    var emergencyHotkeyRegistered = false
    /// The global stop shortcut; the delegate re-registers it when it changes.
    var stopHotkey = StopHotkey.load() {
        didSet { stopHotkey.save(); settingsChanged() }
    }
    private(set) var restoredGlyphs = UserDefaults.standard.object(forKey: "restoredGlyphs") as? Bool
        ?? DreamsPreset.restoredGlyphs

    func setTransparentBackground(_ enabled: Bool) throws {
        guard enabled != transparentBackground else { return }
        defer { settingsChanged() }
        transparentBackground = enabled
        UserDefaults.standard.set(enabled, forKey: "transparentBackground")
        rainGlow = Self.storedGlow(transparent: enabled)
        rainColor = Self.storedRainColor(transparent: enabled)
        // Window opacity is fixed when the overlay is created: recreate a running Matrix,
        // keeping the time it has left.
        if rainRequested {
            // Over windows the rain has no run time; on black it keeps the time it has left.
            let remaining = expiresAt.map { max(1, $0.timeIntervalSinceNow) } ?? (runTimeSeconds > 0 ? runTimeSeconds : nil)
            try begin(duration: enabled ? nil : remaining, brightness: lastBrightness)
        }
    }

    /// Every setting back to `DreamsPreset`, for both backgrounds. Live renderers follow at once.
    func resetToDefaults() throws {
        let defaults = UserDefaults.standard
        for key in ["rainColor", "transparentRainColor", "rainGlow", "transparentRainGlow"] {
            defaults.removeObject(forKey: key)
        }
        try setTransparentBackground(DreamsPreset.transparentBackground)
        rainGlow = Self.storedGlow(transparent: transparentBackground)
        rainColor = Self.storedRainColor(transparent: transparentBackground)
        rainColumnCount = DreamsPreset.columnCount
        rainDensity = DreamsPreset.density
        rainFadeRows = DreamsPreset.fadeRows
        rainSpeed = DreamsPreset.speed
        rainSearchFraction = DreamsPreset.searchFraction
        rainDecelerationEnabled = DreamsPreset.decelerationEnabled
        rainDeceleration = DreamsPreset.deceleration
        rainBrightnessSpread = DreamsPreset.brightnessSpread
        rainPulseStrength = DreamsPreset.pulseStrength
        rainIdleIntensity = DreamsPreset.idleIntensity
        let words = DreamsPreset.keywordColor
        keywordColor = NSColor(srgbRed: words[0], green: words[1], blue: words[2], alpha: 1)
        keywordBrightness = DreamsPreset.keywordBrightness
        try setRestoredGlyphs(DreamsPreset.restoredGlyphs)
        setHideFromScreenshots(DreamsPreset.hideFromScreenshots)
        runTimeSeconds = DreamsPreset.runTimeSeconds
        showsMenuBarIcon = DreamsPreset.showsMenuBarIcon
        stopHotkey = .standard
        try setDisplaySelection(RainDisplaySelection())
    }

    /// Keeps the overlay out of screenshots, recordings and the system screenshot tool's window
    /// picker, so the windows under the rain can be captured. Applies to a running overlay at once.
    private(set) var hideFromScreenshots = UserDefaults.standard.object(forKey: "hideFromScreenshots") as? Bool
        ?? DreamsPreset.hideFromScreenshots

    func setHideFromScreenshots(_ enabled: Bool) {
        hideFromScreenshots = enabled
        UserDefaults.standard.set(enabled, forKey: "hideFromScreenshots")
        screenManager.orderedOverlays.forEach { $0.window.sharingType = enabled ? .none : .readOnly }
        settingsChanged()
    }

    /// The system screenshot tool picks the window under the cursor, and the full-screen overlay is
    /// always the topmost one, so it would be picked (and, being hidden from capture, could not be
    /// captured). While the tool's picker is on screen the overlay steps aside, then comes back.
    private func watchForScreenshotTool() {
        captureWatcher?.invalidate()
        captureWatcher = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkScreenshotTool() }
        }
    }

    private func checkScreenshotTool() {
        guard rainIsOn else { return }
        checkScreenshotTool(active: hideFromScreenshots && Self.screenshotToolIsActive(), at: Date())
    }

    /// Apply a capture-tool observation; explicit time keeps the restore grace period deterministic.
    func checkScreenshotTool(active screenshotToolActive: Bool, at now: Date) {
        guard rainIsOn else { return }
        let active = hideFromScreenshots && screenshotToolActive
        if active {
            captureClearSince = nil
            if !suspendedForCapture {
                suspendedForCapture = true
                screenManager.orderedOverlays.forEach { $0.window.orderOut(nil) }
            }
        } else if suspendedForCapture {
            let since = captureClearSince ?? now
            captureClearSince = since
            // A short grace period: the picker's windows go away a moment before the capture is saved.
            if now.timeIntervalSince(since) > 0.5 {
                suspendedForCapture = false
                captureClearSince = nil
                screenManager.orderedOverlays.forEach { $0.window.orderFrontRegardless() }
            }
        }
    }

    /// The picker (⇧⌘4, window mode), ⇧⌘5 and `screencapture -i` show windows owned by these processes.
    private static func screenshotToolIsActive() -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains { window in
            guard let owner = window[kCGWindowOwnerName as String] as? String else { return false }
            return owner == "screencapture" || owner == "screencaptureui"
        }
    }

    func setRestoredGlyphs(_ enabled: Bool) throws {
        guard enabled != restoredGlyphs else { return }
        for renderer in screenManager.renderers { try renderer.setRestoredGlyphs(enabled) }
        restoredGlyphs = enabled
        UserDefaults.standard.set(enabled, forKey: "restoredGlyphs")
        settingsChanged()
    }
    /// Zero keeps the original automatic grid; otherwise use an exact horizontal count.
    var rainColumnCount: Int = {
        let value = UserDefaults.standard.integer(forKey: "rainColumnCount")
        return value == 0 ? 0 : min(240, max(24, value))
    }() {
        didSet {
            UserDefaults.standard.set(rainColumnCount, forKey: "rainColumnCount")
            screenManager.renderers.forEach { $0.rainColumnCount = rainColumnCount }
            settingsChanged()
        }
    }

    private var rainScreen: NSScreen? {
        screenManager.targetScreens.first
    }

    var automaticColumnCount: Int {
        let size = rainScreen?.frame.size ?? NSSize(width: 1512, height: 982)
        return max(24, Int(size.width / size.height * 72))
    }

    var rainDensity: Double = {
        let value = UserDefaults.standard.object(forKey: "rainDensity") as? Double ?? DreamsPreset.density
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.density
    }() {
        didSet {
            UserDefaults.standard.set(rainDensity, forKey: "rainDensity")
            screenManager.renderers.forEach { $0.rainDensity = rainDensity }
            settingsChanged()
        }
    }

    var rainFadeRows: Double = {
        let value = UserDefaults.standard.object(forKey: "rainFadeRows") as? Double ?? DreamsPreset.fadeRows
        return value.isFinite ? min(16, max(1, value)) : DreamsPreset.fadeRows
    }() {
        didSet {
            UserDefaults.standard.set(rainFadeRows, forKey: "rainFadeRows")
            screenManager.renderers.forEach { $0.rainFadeRows = rainFadeRows }
            settingsChanged()
        }
    }

    var rainSpeed: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSpeed") as? Double ?? DreamsPreset.speed
        return value.isFinite ? min(3, max(0.25, value)) : DreamsPreset.speed
    }() {
        didSet {
            UserDefaults.standard.set(rainSpeed, forKey: "rainSpeed")
            screenManager.renderers.forEach { $0.rainSpeed = rainSpeed }
            settingsChanged()
        }
    }

    var rainSearchFraction: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSearchFraction") as? Double ?? DreamsPreset.searchFraction
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.searchFraction
    }() {
        didSet {
            UserDefaults.standard.set(rainSearchFraction, forKey: "rainSearchFraction")
            screenManager.renderers.forEach { $0.rainSearchFraction = rainSearchFraction }
            settingsChanged()
        }
    }

    var rainDecelerationEnabled = UserDefaults.standard.object(forKey: "rainDecelerationEnabled") as? Bool
        ?? DreamsPreset.decelerationEnabled {
        didSet {
            UserDefaults.standard.set(rainDecelerationEnabled, forKey: "rainDecelerationEnabled")
            updateDeceleration()
            settingsChanged()
        }
    }
    var rainDeceleration: Double = {
        let value = UserDefaults.standard.object(forKey: "rainDeceleration") as? Double ?? DreamsPreset.deceleration
        return MatrixSimulation.Deceleration(acceleration: value).acceleration
    }() {
        didSet {
            UserDefaults.standard.set(rainDeceleration, forKey: "rainDeceleration")
            updateDeceleration()
            settingsChanged()
        }
    }
    private var dropDeceleration: MatrixSimulation.Deceleration {
        .init(enabled: rainDecelerationEnabled, acceleration: rainDeceleration)
    }
    private func updateDeceleration() {
        screenManager.renderers.forEach { $0.rainDeceleration = dropDeceleration }
    }

    var rainBrightnessSpread: Double = {
        let value = UserDefaults.standard.object(forKey: "rainBrightnessSpread") as? Double ?? DreamsPreset.brightnessSpread
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.brightnessSpread
    }() {
        didSet {
            UserDefaults.standard.set(rainBrightnessSpread, forKey: "rainBrightnessSpread")
            screenManager.renderers.forEach { $0.rainBrightnessSpread = rainBrightnessSpread }
            settingsChanged()
        }
    }

    var rainPulseStrength: Double = {
        let value = UserDefaults.standard.object(forKey: "rainPulseStrength") as? Double ?? DreamsPreset.pulseStrength
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.pulseStrength
    }() {
        didSet {
            UserDefaults.standard.set(rainPulseStrength, forKey: "rainPulseStrength")
            screenManager.renderers.forEach { $0.rainPulseStrength = rainPulseStrength }
            settingsChanged()
        }
    }

    /// Glow is stored per background: a transparent overlay defaults to none, to keep work legible.
    private static func storedGlow(transparent: Bool) -> Double {
        let stored = UserDefaults.standard.object(forKey: transparent ? "transparentRainGlow" : "rainGlow")
        let value = (stored as? Double) ?? (stored as? String).flatMap(Double.init) ?? (transparent ? DreamsPreset.transparentGlow : DreamsPreset.glow)
        return value.isFinite ? min(3, max(0, value)) : DreamsPreset.glow
    }

    var rainGlow: Double = DreamsController.storedGlow(transparent: DreamsController.initialTransparent) {
        didSet {
            UserDefaults.standard.set(rainGlow, forKey:
                transparentBackground ? "transparentRainGlow" : "rainGlow")
            screenManager.renderers.forEach { $0.rainGlow = rainGlow }
            settingsChanged()
        }
    }

    var rainIdleIntensity: Double = {
        let stored = UserDefaults.standard.object(forKey: "rainIdleIntensity")
        let value = (stored as? Double) ?? (stored as? String).flatMap(Double.init) ?? DreamsPreset.idleIntensity
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.idleIntensity
    }() {
        didSet {
            UserDefaults.standard.set(rainIdleIntensity, forKey: "rainIdleIntensity")
            screenManager.renderers.forEach { $0.rainIdleIntensity = rainIdleIntensity }
            settingsChanged()
        }
    }

    var keywordColor: NSColor = {
        let rgb = UserDefaults.standard.array(forKey: "keywordColor") as? [Double] ?? DreamsPreset.keywordColor
        guard rgb.count == 3, rgb.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            let d = DreamsPreset.keywordColor
            return NSColor(srgbRed: d[0], green: d[1], blue: d[2], alpha: 1)
        }
        return NSColor(srgbRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
    }() {
        didSet {
            guard let rgb = keywordColor.usingColorSpace(.sRGB) else { return }
            UserDefaults.standard.set([rgb.redComponent, rgb.greenComponent, rgb.blueComponent], forKey: "keywordColor")
            screenManager.renderers.forEach { $0.keywordTint = keywordTint }
            settingsChanged()
        }
    }
    var keywordBrightness: Double = {
        let stored = UserDefaults.standard.object(forKey: "keywordBrightness")
        let value = (stored as? Double) ?? (stored as? String).flatMap(Double.init) ?? DreamsPreset.keywordBrightness
        return value.isFinite ? min(2, max(0, value)) : DreamsPreset.keywordBrightness
    }() {
        didSet {
            UserDefaults.standard.set(keywordBrightness, forKey: "keywordBrightness")
            screenManager.renderers.forEach { $0.keywordBrightness = keywordBrightness }
            settingsChanged()
        }
    }
    /// Rain letter colour, stored per background like glow. The swatch shows the on-screen colour:
    /// the rain is shaded in linear light and written to an sRGB drawable.
    private static func storedRainColor(transparent: Bool) -> NSColor {
        let fallback = transparent ? DreamsPreset.transparentRainColor : DreamsPreset.rainColor
        let stored = UserDefaults.standard.array(forKey: transparent ? "transparentRainColor" : "rainColor") as? [Double]
        let rgb = stored.flatMap { $0.count == 3 && $0.allSatisfy({ $0.isFinite && (0...1).contains($0) }) ? $0 : nil } ?? fallback
        return NSColor(srgbRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
    }

    var rainColor: NSColor = DreamsController.storedRainColor(transparent: DreamsController.initialTransparent) {
        didSet {
            guard let rgb = rainColor.usingColorSpace(.sRGB) else { return }
            UserDefaults.standard.set([rgb.redComponent, rgb.greenComponent, rgb.blueComponent],
                forKey: transparentBackground ? "transparentRainColor" : "rainColor")
            screenManager.renderers.forEach { $0.rainTint = rainTint }
            settingsChanged()
        }
    }

    private var rainTint: SIMD3<Float> {
        let rgb = rainColor.usingColorSpace(.sRGB)!
        func linear(_ v: CGFloat) -> Float {
            let x = Float(v)
            return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        return SIMD3(linear(rgb.redComponent), linear(rgb.greenComponent), linear(rgb.blueComponent))
    }

    private var keywordTint: SIMD3<Float> {
        let rgb = keywordColor.usingColorSpace(.sRGB)!
        return SIMD3(Float(rgb.redComponent), Float(rgb.greenComponent), Float(rgb.blueComponent))
    }

    var animationStatus: String {
        if let displayError { return L("status.displayError", displayError) }
        if rainRequested && !rainIsOn { return L("status.waitingDisplay") }
        guard rainIsOn, let renderer else {
            switch lastStopReason {
            case .some(.restart), .none: return L("status.stopped")
            case .some(let reason): return L("status.stopped." + reason.rawValue)
            }
        }
        guard let expiresAt else { return L("status.rendering.unlimited", renderer.framesRendered) }
        return L("status.rendering", renderer.framesRendered, max(0, Int(expiresAt.timeIntervalSinceNow)))
    }

    func status() throws -> [String: Any] {
        let messages = try KeywordFeed().snapshot()
        return [
            "working_agents": messages.filter(\.isWorking).count,
            "activity_level": KeywordMessage.workLevel(messages),
            "action_pressure": KeywordMessage.pressure(messages),
            "keyword_sessions": messages.map { message in
                ["session_id": message.sessionID, "keywords": message.words,
                 "color": message.color, "activity": message.isWorking ? "working" : "idle",
                 "expires_at": ISO8601DateFormatter().string(from: message.expiresAt)] as [String: Any]
            },
            "rain_visible": rainIsOn && !suspendedForCapture,
            "rain_suspended_for_capture": rainIsOn && suspendedForCapture,
            "rain_requested": rainRequested,
            "display_mode": displaySelection.mode.rawValue,
            "selected_display_ids": displaySelection.selectedIDs.sorted(),
            "display_error": displayError as Any? ?? NSNull(),
            "rain_windows": screenManager.overlays.keys.sorted().compactMap { id -> [String: Any]? in
                guard let overlay = screenManager.overlays[id] else { return nil }
                return ["display_uuid": id, "display_id": Int(overlay.displayID),
                        "window_number": overlay.window.windowNumber, "frames_rendered": overlay.renderer.framesRendered]
            },
            "transparent_background": transparentBackground,
            "hidden_from_screenshots": hideFromScreenshots,
            "rain_columns": rainColumnCount,
            "rain_density": rainDensity,
            "rain_fade_rows": rainFadeRows,
            "rain_speed": rainSpeed,
            "rain_search_fraction": rainSearchFraction,
            "rain_deceleration_enabled": rainDecelerationEnabled,
            "rain_deceleration": dropDeceleration.acceleration,
            "rain_brightness_spread": rainBrightnessSpread,
            "rain_pulse_strength": rainPulseStrength,
            "rain_glow": rainGlow,
            "keyword_color_rgb": [keywordTint.x, keywordTint.y, keywordTint.z],
            "rain_color_rgb": [rainTint.x, rainTint.y, rainTint.z],
            "keyword_brightness": keywordBrightness,
            "rain_idle_intensity": rainIdleIntensity,
            "matrix_font": restoredGlyphs ? "restored" : "classic",
            "rain_window_number": overlay.map { $0.windowNumber as Any } ?? NSNull(),
            "frames_rendered": screenManager.renderers.reduce(0) { $0 + $1.framesRendered },
            "emergency_hotkey_registered": emergencyHotkeyRegistered,
            "stop_hotkey": stopHotkey.display,
            "virtual_display_id": virtualDisplay.map { Int($0.displayID) as Any } ?? NSNull(),
            "private_virtual_display_api_available": DreamsVirtualDisplay.isAvailable(),
            "workspace_clicks": clicks,
            "workspace_window_number": workspaceWindow.map { $0.windowNumber as Any } ?? NSNull(),
            "workspace_window_display_id": workspaceWindow?.screen.map { Int($0.displayID) as Any } ?? NSNull(),
            "expires_at": expiresAt.map { ISO8601DateFormatter().string(from: $0) as Any } ?? NSNull(),
            "run_time_seconds": runTimeSeconds,
            "last_stop_reason": lastStopReason?.rawValue ?? NSNull(),
            "prevents_idle_sleep": assertionActive,
            "displays": NSScreen.screens.map { screen in
                let bounds = CGDisplayBounds(screen.displayID)
                return ["id": Int(screen.displayID), "name": screen.localizedName,
                        "uuid": screen.stableDisplayID, "excluded": screen.displayID == screenManager.excludedDisplayID,
                        "built_in": CGDisplayIsBuiltin(screen.displayID) != 0,
                        "is_main": screen.displayID == CGMainDisplayID(),
                        "quartz_bounds": ["x": bounds.minX, "y": bounds.minY,
                                          "width": bounds.width, "height": bounds.height]] as [String: Any]
            }
        ]
    }

    func statusJSON() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: try status(), options: [.sortedKeys])
        return String(bytes: data, encoding: .utf8) ?? "{}"
    }

    /// The MCP entry point: an explicit duration of 1...3600 seconds.
    func start(duration: Double = 300, brightness: Double = 0.18) throws {
        guard duration.isFinite, (1...3600).contains(duration),
              brightness.isFinite, (0.02...0.35).contains(brightness) else {
            throw DreamsError.unavailable("duration_seconds must be 1...3600; brightness must be 0.02...0.35.")
        }
        try begin(duration: duration, brightness: brightness)
    }

    /// The window and the menu. On black the rain covers the screen, so it follows the "Run time"
    /// setting (0 = until stopped); over windows (transparent) it runs until it is stopped.
    func startWithRunTime() throws {
        let limited = !transparentBackground && runTimeSeconds > 0
        try begin(duration: limited ? runTimeSeconds : nil, brightness: 0.18)
    }

    /// Opening the app again brings the window back and, on black, stops the rain that covers it.
    func stopForReopen() {
        if !transparentBackground { stop(reason: .reopen) }
    }

    func configureRenderer(_ renderer: RainRenderer) {
        renderer.keywordTint = keywordTint
        renderer.rainTint = rainTint
        renderer.keywordBrightness = keywordBrightness
        renderer.rainIdleIntensity = rainIdleIntensity
        renderer.rainGlow = rainGlow
        renderer.rainSpeed = rainSpeed
        renderer.rainSearchFraction = rainSearchFraction
        renderer.rainDeceleration = dropDeceleration
        renderer.rainBrightnessSpread = rainBrightnessSpread
        renderer.rainPulseStrength = rainPulseStrength
        renderer.rainFadeRows = rainFadeRows
        renderer.rainColumnCount = rainColumnCount
        renderer.rainDensity = rainDensity
        renderer.brightness = Float(lastBrightness)
    }

    private func begin(duration: Double?, brightness: Double) throws {
        guard !screenManager.targetScreens.isEmpty else {
            throw DreamsError.unavailable(L("display.none"))
        }
        stop(reason: .restart)
        lastDuration = duration
        lastBrightness = brightness
        rainRequested = true
        do { try reconcileScreens() }
        catch { stop(reason: .restart); throw error }
        lastStopReason = nil
        watchForScreenshotTool()
        guard let duration else { return }
        expiresAt = Date().addingTimeInterval(duration)
        expiryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
            self?.stop(reason: .timer)
        }
    }

    func showEventFixtures() throws {
        if !rainIsOn { try startWithRunTime() }
        try KeywordInput.publishFixtures()
        // The demo loops an agent turn: each fixture message floods the rain like a real one
        // (RainActivity.surge), the call lines are printed, the rain settles to calm, and after
        // a short pause the next turn starts — until the rain stops (Esc or timeout;
        // start() and stop() cancel it).
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            while let self {
                // Wait for the event wave (~8.5 s at 1x, stretched by the speed slider) and for
                // the surge to settle (≈ attack + hold + 3 decay constants), then pause briefly.
                let wave = 8.5 / max(0.25, self.rainSpeed)
                let settle = RainActivity.attack + RainActivity.hold + 3 * RainActivity.decay
                do { try await Task.sleep(for: .seconds(max(wave, settle) + 2)) } catch { return }
                guard self.rainIsOn else { return }
                try? KeywordInput.publishFixtures()
            }
        }
    }

    func handleEscape() {
        if !transparentBackground { stop(reason: .escape) }
    }

    func stop(reason: StopReason = .user) {
        if rainRequested && reason != .restart {
            lastStopReason = reason
            log.notice("Rain stopped: \(reason.rawValue, privacy: .public)")
        }
        expiryTask?.cancel()
        expiryTask = nil
        demoTask?.cancel()
        demoTask = nil
        captureWatcher?.invalidate()
        captureWatcher = nil
        suspendedForCapture = false
        captureClearSince = nil
        rainRequested = false
        screenManager.close()
        expiresAt = nil
        displayError = nil
        updateSleepAssertion()
    }

    func resume() throws { try begin(duration: lastDuration, brightness: lastBrightness) }

    func previewPNG() async throws -> Data {
        if let renderer { return try await renderer.previewPNG() }
        let renderer = try RainRenderer(view: MTKView(frame: .zero), restoredGlyphs: restoredGlyphs,
            transparentBackground: transparentBackground)
        configureRenderer(renderer)
        return try await renderer.previewPNG(posedTime: 6)
    }

    func createWorkspace() async throws {
        if virtualDisplay != nil { return }
        // Private API, opt-in tool only. Never change the user's primary display or mirror settings.
        let display = try DreamsVirtualDisplay(width: 1512, height: 982)
        virtualDisplay = display
        screenManager.excludedDisplayID = display.displayID
        screenParametersChanged()
        var screen: NSScreen?
        for _ in 0..<30 {
            guard virtualDisplay?.displayID == display.displayID else {
                throw DreamsError.unavailable("Virtual workspace creation was cancelled.")
            }
            screen = NSScreen.screens.first { $0.displayID == display.displayID }
            if screen != nil { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        guard let screen else {
            virtualDisplay = nil
            screenManager.excludedDisplayID = nil
            screenParametersChanged()
            throw DreamsError.unavailable("Virtual display did not become available to AppKit within 3 seconds.")
        }
        clicks = 0
        counterLabel.stringValue = "Clicks: 0"
        let window = NSWindow(contentRect: NSRect(x: screen.visibleFrame.minX + 100,
            y: screen.visibleFrame.minY + 100, width: 820, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false, screen: screen)
        window.title = "Dreams Agent Workspace"
        window.isReleasedWhenClosed = false
        let heading = NSTextField(labelWithString: "Dreams · Agent Workspace")
        heading.font = .systemFont(ofSize: 30, weight: .semibold)
        let detail = NSTextField(wrappingLabelWithString:
            "This test window lives on a virtual display. The selected screens can show the rain while an agent reads and clicks here.")
        detail.font = .systemFont(ofSize: 17)
        detail.preferredMaxLayoutWidth = 640
        counterLabel.font = .monospacedDigitSystemFont(ofSize: 36, weight: .medium)
        let button = NSButton(title: "Increment", target: self, action: #selector(increment))
        button.bezelStyle = .rounded
        button.setAccessibilityIdentifier("dreams.increment")
        let stack = NSStackView(views: [heading, detail, counterLabel, button])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 48),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -48),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])
        window.contentView = content
        workspaceWindow = window
        window.makeKeyAndOrderFront(nil)
        window.setFrameOrigin(NSPoint(x: screen.visibleFrame.minX + 100, y: screen.visibleFrame.minY + 100))
        try await Task.sleep(for: .milliseconds(150))
    }

    @objc private func increment() {
        clicks += 1
        counterLabel.stringValue = "Clicks: \(clicks)"
    }

    func closeWorkspace() {
        workspaceWindow?.close()
        workspaceWindow = nil
        // Keep its ID excluded until after releasing the virtual display and its AppKit screen.
        virtualDisplay = nil
        screenParametersChanged()
    }

    func cleanUp() {
        stop(reason: .restart)
        closeWorkspace()
    }
}
