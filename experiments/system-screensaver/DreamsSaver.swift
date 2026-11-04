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
        let view = MTKView(frame: bounds)
        view.autoresizingMask = [.width, .height]
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        do {
            renderer = try RainRenderer(view: view)
            metalView = view
            addSubview(view)
        } catch {
            NSLog("Dreams screen saver renderer failed: %@", String(describing: error))
        }
    }

    override func startAnimation() {
        super.startAnimation()
        metalView?.isPaused = false
    }

    override func stopAnimation() {
        metalView?.isPaused = true
        super.stopAnimation()
    }
}
