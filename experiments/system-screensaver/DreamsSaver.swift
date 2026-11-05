import AppKit
import MetalKit
import ScreenSaver

extension Bundle {
    static var module: Bundle { Bundle(for: DreamsSystemSaverView.self) }
}

@objc(DreamsSystemSaverView)
final class DreamsSystemSaverView: ScreenSaverView {
    private var metalView: MTKView?
    private var renderer: RainRenderer?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let began = ProcessInfo.processInfo.systemUptime
        let view = MTKView(frame: bounds)
        view.autoresizingMask = [.width, .height]
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        do {
            let renderer = try RainRenderer(view: view)
            self.renderer = renderer
            metalView = view
            addSubview(view)
            NSLog("Dreams saver: renderer initialized in %.3f seconds; preview=%@",
                  ProcessInfo.processInfo.systemUptime - began, isPreview ? "yes" : "no")
        } catch {
            NSLog("Dreams screen saver renderer failed: %@", String(describing: error))
        }
    }

    override func startAnimation() {
        super.startAnimation()
        if renderer == nil { setup() }
        if let color = ScreenSaverRainColor.read() {
            renderer?.rainTint = color
            NSLog("Dreams saver: shared rain color loaded")
        } else {
            NSLog("Dreams saver: shared rain color unavailable; using renderer default")
        }
        metalView?.isPaused = false
        NSLog("Dreams saver: animation started; renderer=%@", renderer == nil ? "unavailable" : "ready")
    }

    override func stopAnimation() {
        metalView?.isPaused = true
        NSLog("Dreams saver: animation stopped")
        super.stopAnimation()
    }
}
