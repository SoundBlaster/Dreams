import AppKit
import MetalKit
import IOKit.pwr_mgt
import VirtualDisplayBridge

enum DreamsError: LocalizedError {
    case unavailable(String)
    var errorDescription: String? { if case .unavailable(let message) = self { message } else { nil } }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}

/// The default look: what a first launch (or a missing setting) falls back to.
enum DreamsPreset {
    static let density = 0.0
    static let fadeRows = 3.0
    static let speed = 0.43
    static let brightnessSpread = 0.51
    static let glow = 0.57
    static let transparentGlow = 0.0
    static let idleIntensity = 0.77
    static let keywordColor = [0.0, 1.0, 0.39]
    static let keywordBrightness = 2.0
    static let restoredGlyphs = true
    static let transparentBackground = false
    static let hideFromScreenshots = true
    /// Black background: the classic dark film green. Transparent: a light mint that reads on bright desktops.
    static let rainColor = [0.086, 0.547, 0.26]
    static let transparentRainColor = [0.35, 1.0, 0.55]
}

@MainActor
final class DreamsController: NSObject {
    /// Transparent Matrix: a saved setting; the `--transparent` launch flag still turns it on.
    private(set) var transparentBackground = DreamsController.initialTransparent
    private static let initialTransparent = CommandLine.arguments.contains("--transparent")
        || UserDefaults.standard.bool(forKey: "transparentBackground")
    private var overlay: NSWindow?
    private var renderer: RainRenderer?
    private var expiryTask: Task<Void, Never>?
    private var demoTask: Task<Void, Never>?
    private var virtualDisplay: DreamsVirtualDisplay?
    private var workspaceWindow: NSWindow?
    private let counterLabel = NSTextField(labelWithString: "Clicks: 0")
    private var clicks = 0
    private var assertionID: IOPMAssertionID = 0
    private var assertionActive = false
    private var expiresAt: Date?
    private var lastDuration = 300.0
    private var lastBrightness = 0.18
    var emergencyHotkeyRegistered = false
    private(set) var restoredGlyphs = UserDefaults.standard.object(forKey: "restoredGlyphs") as? Bool
        ?? DreamsPreset.restoredGlyphs

    func setTransparentBackground(_ enabled: Bool) throws {
        guard enabled != transparentBackground else { return }
        transparentBackground = enabled
        UserDefaults.standard.set(enabled, forKey: "transparentBackground")
        rainGlow = Self.storedGlow(transparent: enabled)
        rainColor = Self.storedRainColor(transparent: enabled)
        // Window opacity is fixed when the overlay is created: recreate a running Matrix,
        // keeping the time it has left.
        if overlay?.isVisible == true {
            let remaining = max(1, min(3600, expiresAt?.timeIntervalSinceNow ?? lastDuration))
            try start(duration: remaining, brightness: lastBrightness)
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
        rainDensity = DreamsPreset.density
        rainFadeRows = DreamsPreset.fadeRows
        rainSpeed = DreamsPreset.speed
        rainBrightnessSpread = DreamsPreset.brightnessSpread
        rainIdleIntensity = DreamsPreset.idleIntensity
        let words = DreamsPreset.keywordColor
        keywordColor = NSColor(srgbRed: words[0], green: words[1], blue: words[2], alpha: 1)
        keywordBrightness = DreamsPreset.keywordBrightness
        try setRestoredGlyphs(DreamsPreset.restoredGlyphs)
        setHideFromScreenshots(DreamsPreset.hideFromScreenshots)
    }

    /// Keeps the overlay out of screenshots, recordings and the system screenshot tool's window
    /// picker, so the windows under the rain can be captured. Applies to a running overlay at once.
    private(set) var hideFromScreenshots = UserDefaults.standard.object(forKey: "hideFromScreenshots") as? Bool
        ?? DreamsPreset.hideFromScreenshots

    func setHideFromScreenshots(_ enabled: Bool) {
        hideFromScreenshots = enabled
        UserDefaults.standard.set(enabled, forKey: "hideFromScreenshots")
        overlay?.sharingType = enabled ? .none : .readOnly
    }

    func setRestoredGlyphs(_ enabled: Bool) throws {
        guard enabled != restoredGlyphs else { return }
        try renderer?.setRestoredGlyphs(enabled)
        restoredGlyphs = enabled
        UserDefaults.standard.set(enabled, forKey: "restoredGlyphs")
    }
    var rainDensity: Double = {
        let value = UserDefaults.standard.object(forKey: "rainDensity") as? Double ?? DreamsPreset.density
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.density
    }() {
        didSet {
            UserDefaults.standard.set(rainDensity, forKey: "rainDensity")
            renderer?.rainDensity = rainDensity
        }
    }

    var rainFadeRows: Double = {
        let value = UserDefaults.standard.object(forKey: "rainFadeRows") as? Double ?? DreamsPreset.fadeRows
        return value.isFinite ? min(16, max(1, value)) : DreamsPreset.fadeRows
    }() {
        didSet {
            UserDefaults.standard.set(rainFadeRows, forKey: "rainFadeRows")
            renderer?.rainFadeRows = rainFadeRows
        }
    }

    var rainSpeed: Double = {
        let value = UserDefaults.standard.object(forKey: "rainSpeed") as? Double ?? DreamsPreset.speed
        return value.isFinite ? min(3, max(0.25, value)) : DreamsPreset.speed
    }() {
        didSet {
            UserDefaults.standard.set(rainSpeed, forKey: "rainSpeed")
            renderer?.rainSpeed = rainSpeed
        }
    }

    var rainBrightnessSpread: Double = {
        let value = UserDefaults.standard.object(forKey: "rainBrightnessSpread") as? Double ?? DreamsPreset.brightnessSpread
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.brightnessSpread
    }() {
        didSet {
            UserDefaults.standard.set(rainBrightnessSpread, forKey: "rainBrightnessSpread")
            renderer?.rainBrightnessSpread = rainBrightnessSpread
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
            renderer?.rainGlow = rainGlow
        }
    }

    var rainIdleIntensity: Double = {
        let stored = UserDefaults.standard.object(forKey: "rainIdleIntensity")
        let value = (stored as? Double) ?? (stored as? String).flatMap(Double.init) ?? DreamsPreset.idleIntensity
        return value.isFinite ? min(1, max(0, value)) : DreamsPreset.idleIntensity
    }() {
        didSet {
            UserDefaults.standard.set(rainIdleIntensity, forKey: "rainIdleIntensity")
            renderer?.rainIdleIntensity = rainIdleIntensity
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
            renderer?.keywordTint = keywordTint
        }
    }
    var keywordBrightness: Double = {
        let stored = UserDefaults.standard.object(forKey: "keywordBrightness")
        let value = (stored as? Double) ?? (stored as? String).flatMap(Double.init) ?? DreamsPreset.keywordBrightness
        return value.isFinite ? min(2, max(0, value)) : DreamsPreset.keywordBrightness
    }() {
        didSet {
            UserDefaults.standard.set(keywordBrightness, forKey: "keywordBrightness")
            renderer?.keywordBrightness = keywordBrightness
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
            renderer?.rainTint = rainTint
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
        guard overlay?.isVisible == true, let renderer else {
            return L("status.stopped")
        }
        let remaining = max(0, Int(expiresAt?.timeIntervalSinceNow ?? 0))
        return L("status.rendering", renderer.framesRendered, remaining)
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
            "rain_visible": overlay?.isVisible ?? false,
            "transparent_background": transparentBackground,
            "hidden_from_screenshots": hideFromScreenshots,
            "rain_density": rainDensity,
            "rain_fade_rows": rainFadeRows,
            "rain_speed": rainSpeed,
            "rain_brightness_spread": rainBrightnessSpread,
            "rain_glow": rainGlow,
            "keyword_color_rgb": [keywordTint.x, keywordTint.y, keywordTint.z],
            "rain_color_rgb": [rainTint.x, rainTint.y, rainTint.z],
            "keyword_brightness": keywordBrightness,
            "rain_idle_intensity": rainIdleIntensity,
            "matrix_font": restoredGlyphs ? "restored" : "classic",
            "rain_window_number": overlay.map { $0.windowNumber as Any } ?? NSNull(),
            "frames_rendered": renderer?.framesRendered ?? 0,
            "emergency_hotkey_registered": emergencyHotkeyRegistered,
            "virtual_display_id": virtualDisplay.map { Int($0.displayID) as Any } ?? NSNull(),
            "private_virtual_display_api_available": DreamsVirtualDisplay.isAvailable(),
            "workspace_clicks": clicks,
            "workspace_window_number": workspaceWindow.map { $0.windowNumber as Any } ?? NSNull(),
            "workspace_window_display_id": workspaceWindow?.screen.map { Int($0.displayID) as Any } ?? NSNull(),
            "expires_at": expiresAt.map { ISO8601DateFormatter().string(from: $0) as Any } ?? NSNull(),
            "prevents_idle_sleep": assertionActive,
            "displays": NSScreen.screens.map { screen in
                let bounds = CGDisplayBounds(screen.displayID)
                return ["id": Int(screen.displayID), "name": screen.localizedName,
                        "built_in": CGDisplayIsBuiltin(screen.displayID) != 0,
                        "is_main": screen.displayID == CGMainDisplayID(),
                        "quartz_bounds": ["x": bounds.minX, "y": bounds.minY,
                                          "width": bounds.width, "height": bounds.height]] as [String: Any]
            }
        ]
    }

    func statusJSON() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: try status(), options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    func start(duration: Double = 300, brightness: Double = 0.18) throws {
        guard duration.isFinite, (1...3600).contains(duration),
              brightness.isFinite, (0.02...0.35).contains(brightness) else {
            throw DreamsError.unavailable("duration_seconds must be 1...3600; brightness must be 0.02...0.35.")
        }
        guard let screen = NSScreen.screens.first(where: { CGDisplayIsBuiltin($0.displayID) != 0 }) else {
            throw DreamsError.unavailable("No built-in display found. Refusing to cover an arbitrary display.")
        }
        stop()
        let view = MTKView(frame: NSRect(origin: .zero, size: screen.frame.size))
        let transparent = transparentBackground
        let renderer = try RainRenderer(view: view, restoredGlyphs: restoredGlyphs,
            transparentBackground: transparent)
        renderer.keywordTint = keywordTint
        renderer.rainTint = rainTint
        renderer.keywordBrightness = keywordBrightness
        renderer.rainIdleIntensity = rainIdleIntensity
        renderer.rainGlow = rainGlow
        renderer.rainSpeed = rainSpeed
        renderer.rainBrightnessSpread = rainBrightnessSpread
        renderer.rainFadeRows = rainFadeRows
        renderer.rainDensity = rainDensity
        renderer.brightness = Float(brightness)
        let window = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        window.title = "Dreams Rain"
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = true
        window.sharingType = hideFromScreenshots ? .none : .readOnly
        window.isOpaque = !transparent
        window.backgroundColor = transparent ? .clear : .black
        window.hasShadow = false
        window.contentView = view
        window.setFrame(screen.frame, display: true)
        self.renderer = renderer
        overlay = window
        lastDuration = duration
        lastBrightness = brightness
        window.orderFrontRegardless()
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn), "Dreams agent session" as CFString, &assertionID)
        assertionActive = result == kIOReturnSuccess
        expiresAt = Date().addingTimeInterval(duration)
        expiryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
            self?.stop()
        }
    }

    func showEventFixtures() throws {
        if overlay?.isVisible != true { try start() }
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
                guard self.overlay?.isVisible == true else { return }
                try? KeywordInput.publishFixtures()
            }
        }
    }

    func stop() {
        expiryTask?.cancel()
        expiryTask = nil
        demoTask?.cancel()
        demoTask = nil
        (overlay?.contentView as? MTKView)?.isPaused = true
        overlay?.close()
        overlay = nil
        renderer = nil
        expiresAt = nil
        if assertionActive {
            IOPMAssertionRelease(assertionID)
            assertionActive = false
        }
    }

    func resume() throws { try start(duration: lastDuration, brightness: lastBrightness) }

    func previewPNG() async throws -> Data {
        if let renderer { return try await renderer.previewPNG() }
        let renderer = try RainRenderer(view: MTKView(frame: .zero), restoredGlyphs: restoredGlyphs,
            transparentBackground: transparentBackground)
        renderer.keywordTint = keywordTint
        renderer.rainTint = rainTint
        renderer.keywordBrightness = keywordBrightness
        renderer.rainIdleIntensity = rainIdleIntensity
        renderer.rainGlow = rainGlow
        renderer.rainSpeed = rainSpeed
        renderer.rainBrightnessSpread = rainBrightnessSpread
        renderer.rainFadeRows = rainFadeRows
        renderer.rainDensity = rainDensity
        renderer.brightness = Float(lastBrightness)
        return try await renderer.previewPNG(posedTime: 6)
    }

    func createWorkspace() async throws {
        if virtualDisplay != nil { return }
        // Private API, opt-in tool only. Never change the user's primary display or mirror settings.
        let display = try DreamsVirtualDisplay(width: 1512, height: 982)
        virtualDisplay = display
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
            "This test window lives on a virtual display. The built-in screen can show the rain while an agent reads and clicks here.")
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
        virtualDisplay = nil
    }

    func cleanUp() {
        stop()
        closeWorkspace()
    }
}
