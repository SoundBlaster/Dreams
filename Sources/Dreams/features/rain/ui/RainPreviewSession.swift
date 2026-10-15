import AppKit
import MetalKit
import Observation

/// Window-local playback. The production controller owns settings, never this renderer.
@MainActor
@Observable
final class RainPreviewSession: NSObject, MTKViewDelegate {
    @ObservationIgnored private let controller: DreamsController
    @ObservationIgnored private weak var view: MTKView?
    @ObservationIgnored private(set) var renderer: RainRenderer?
    @ObservationIgnored private var background: Bool?
    @ObservationIgnored private var restoredGlyphs: Bool?
    @ObservationIgnored private var lastDraw: Double?
    @ObservationIgnored private(set) var time = 6.0
    @ObservationIgnored private(set) var isVisible = false
    var isPlaying: Bool { didSet { updatePlayback() } }
    private(set) var errorMessage: String?

    init(controller: DreamsController) {
        self.controller = controller
        isPlaying = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        super.init()
    }

    func attach(_ view: MTKView) {
        guard self.view !== view else { return }
        if let previous = self.view { detach(previous) }
        self.view = view
        view.isPaused = true
        view.enableSetNeedsDisplay = true
    }

    func detach(_ view: MTKView) {
        guard self.view === view else { return }
        setVisible(false)
        view.delegate = nil
        self.view = nil
    }

    func visibilityChanged(_ visible: Bool, for view: MTKView) {
        guard self.view === view else { return }
        setVisible(visible)
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        if visible { refresh() }
        else {
            view?.isPaused = true
            view?.delegate = nil
            renderer = nil
            lastDraw = nil
        }
    }

    func refresh() {
        guard isVisible, let view else { return }
        do {
            if renderer == nil || background != controller.transparentBackground || restoredGlyphs != controller.restoredGlyphs {
                renderer = try RainRenderer(view: view, restoredGlyphs: controller.restoredGlyphs,
                                            transparentBackground: controller.transparentBackground)
                background = controller.transparentBackground
                restoredGlyphs = controller.restoredGlyphs
                time = 6
                lastDraw = nil
            }
            if let renderer { controller.configureRenderer(renderer) }
            errorMessage = nil
            view.delegate = self
            updatePlayback()
        } catch {
            view.isPaused = true
            view.delegate = nil
            renderer = nil
            errorMessage = error.localizedDescription
        }
    }

    func reduceMotionChanged(_ enabled: Bool) {
        if enabled { isPlaying = false }
    }

    private func updatePlayback() {
        guard let view else { return }
        let paused = !isPlaying || !isVisible || renderer == nil
        if paused || view.isPaused != paused { lastDraw = nil }
        view.isPaused = paused
        if isVisible && renderer != nil { view.draw() }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard self.view === view, isVisible, let renderer else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if isPlaying, let lastDraw { time += max(0, now - lastDraw) }
        lastDraw = isPlaying ? now : nil
        let referenceSize = (view.window?.screen ?? NSScreen.main).map {
            view.convertToBacking(NSRect(origin: .zero, size: $0.frame.size)).size
        }
        renderer.draw(in: view, posedTime: Float(time), referenceSize: referenceSize)
    }
}
