import AppKit
import MetalKit

/// Opaque rain is an interactive screen saver; transparent rain never takes input.
@MainActor
final class RainOverlayWindow: NSPanel {
    let metalView: MTKView
    private let transparent: Bool
    private let onEscape: () -> Void

    init(frame: NSRect, metalView: MTKView, transparent: Bool,
         onEscape: @escaping () -> Void, onExit: @escaping () -> Void) {
        self.metalView = metalView
        self.transparent = transparent
        self.onEscape = onEscape
        super.init(contentRect: frame, styleMask: transparent ? [.borderless, .nonactivatingPanel] : [.borderless],
                   backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        ignoresMouseEvents = transparent
        acceptsMouseMovedEvents = !transparent
        isOpaque = !transparent
        backgroundColor = transparent ? .clear : .black
        hasShadow = false
        if transparent {
            contentView = metalView
        } else {
            contentView = RainOverlayContentView(metalView: metalView, onExit: onExit)
        }
    }

    override var canBecomeKey: Bool { !transparent }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) {
        if !transparent { onEscape() }
    }
    override func keyDown(with event: NSEvent) {
        if !transparent, event.keyCode == 53 { onEscape() }
        else { super.keyDown(with: event) }
    }
    override func close() {
        (contentView as? RainOverlayContentView)?.stopExitTimer()
        metalView.isPaused = true
        super.close()
    }
}

@MainActor
final class RainOverlayContentView: NSView {
    let exitButton: NSButton
    private let onExit: () -> Void
    private var tracking: NSTrackingArea?
    private var hideTimer: Timer?
    private var hideAt = 0.0
    private var pointerOverButton = false

    init(metalView: MTKView, onExit: @escaping () -> Void) {
        self.onExit = onExit
        exitButton = NSButton(title: L("overlay.exit"), target: nil, action: nil)
        super.init(frame: metalView.frame)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.target = self
        exitButton.action = #selector(exitRain)
        exitButton.bezelStyle = .rounded
        exitButton.controlSize = .large
        exitButton.font = .systemFont(ofSize: 15, weight: .medium)
        exitButton.appearance = NSAppearance(named: .darkAqua)
        exitButton.toolTip = L("overlay.exit.tip")
        exitButton.setAccessibilityIdentifier("dreams.exit-overlay")
        exitButton.setAccessibilityLabel(L("overlay.exit.label"))
        exitButton.setAccessibilityHelp(L("overlay.exit.tip"))
        addSubview(metalView)
        addSubview(exitButton)
        NSLayoutConstraint.activate([
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            exitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            exitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
            exitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            exitButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        setAccessibilityElement(false)
        metalView.setAccessibilityElement(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { revealExitControls() }
        else { stopExitTimer() }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero, options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        pointerOverButton = exitButton.frame.contains(point)
        revealExitControls()
    }
    override func mouseEntered(with event: NSEvent) { revealExitControls() }
    override func mouseExited(with event: NSEvent) {
        pointerOverButton = false
        revealExitControls()
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(self)
        revealExitControls()
    }

    func revealExitControls(at time: Double = ProcessInfo.processInfo.systemUptime) {
        exitButton.isHidden = false
        hideAt = time + 4
        stopExitTimer()
        let timer = Timer(timeInterval: 4, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.hideExitControlsIfIdle() }
        }
        hideTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func hideExitControlsIfIdle(at time: Double = ProcessInfo.processInfo.systemUptime) {
        guard time >= hideAt, !pointerOverButton, window?.firstResponder !== exitButton,
              !NSWorkspace.shared.isVoiceOverEnabled, !NSApplication.shared.isFullKeyboardAccessEnabled else { return }
        exitButton.isHidden = true
    }

    func stopExitTimer() { hideTimer?.invalidate(); hideTimer = nil }
    @objc private func exitRain() { onExit() }
}
