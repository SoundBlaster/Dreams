import AppKit
import MetalKit
import SwiftUI

struct RainPreviewSurface: NSViewRepresentable {
    let session: RainPreviewSession

    func makeNSView(context: Context) -> RainPreviewView {
        let view = RainPreviewView(frame: .zero)
        view.wantsLayer = true
        view.session = session
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.image)
        view.setAccessibilityLabel(L("native.preview.title"))
        view.setAccessibilityIdentifier("dreams.native.preview")
        session.attach(view)
        return view
    }

    func updateNSView(_ view: RainPreviewView, context: Context) { view.refreshVisibility() }

    static func dismantleNSView(_ view: RainPreviewView, coordinator: ()) {
        view.invalidate()
    }
}

@MainActor
final class RainPreviewView: MTKView {
    weak var session: RainPreviewSession?
    private var observers: [NSObjectProtocol] = []
    private var closing = false

    isolated deinit { removeObservers() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        removeObservers()
        closing = false
        if let window {
            observe(NSWindow.willCloseNotification, object: window) {
                $0.closing = true
                $0.session?.visibilityChanged(false, for: $0)
            }
            observe(NSWindow.willMiniaturizeNotification, object: window) { $0.session?.visibilityChanged(false, for: $0) }
            for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                         NSWindow.didDeminiaturizeNotification, NSWindow.didBecomeKeyNotification] {
                observe(name, object: window) {
                    if name == NSWindow.didBecomeKeyNotification { $0.closing = false }
                    $0.refreshVisibility()
                }
            }
        }
        for name in [NSApplication.didHideNotification, NSApplication.didUnhideNotification] {
            observe(name, object: NSApp) { $0.refreshVisibility() }
        }
        let token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.session?.reduceMotionChanged(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) } }
        observers.append(token)
        refreshVisibility()
        Task { @MainActor [weak self] in self?.refreshVisibility() }
    }

    override func layout() { super.layout(); refreshVisibility() }

    override func viewDidHide() { super.viewDidHide(); refreshVisibility() }
    override func viewDidUnhide() { super.viewDidUnhide(); refreshVisibility() }

    func refreshVisibility() {
        let visible = window.map { $0.isVisible && !$0.isMiniaturized && $0.occlusionState.contains(.visible) } ?? false
        session?.visibilityChanged(visible && !closing && !isHiddenOrHasHiddenAncestor && !NSApp.isHidden, for: self)
    }

    func invalidate() {
        removeObservers()
        session?.detach(self)
        session = nil
    }

    private func observe(_ name: Notification.Name, object: AnyObject?, action: @escaping @MainActor (RainPreviewView) -> Void) {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let self { action(self) } }
        }
        observers.append(token)
    }

    private func removeObservers() {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        observers.removeAll()
    }
}
