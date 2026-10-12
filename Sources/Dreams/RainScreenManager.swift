import AppKit
import MetalKit

extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    var stableDisplayID: String {
        if let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() {
            return CFUUIDCreateString(nil, uuid) as String
        }
        return "display-\(displayID)"
    }
}

@MainActor
final class RainScreenManager {
    @MainActor
    struct Overlay {
        let displayID: CGDirectDisplayID
        let window: NSWindow
        let renderer: RainRenderer

        func close() {
            (window.contentView as? MTKView)?.isPaused = true
            window.close()
        }
    }

    var selection = RainDisplaySelection.load()
    var excludedDisplayID: CGDirectDisplayID?
    private(set) var overlays: [String: Overlay] = [:]
    var orderedOverlays: [Overlay] { overlays.keys.sorted().compactMap { overlays[$0] } }
    var renderers: [RainRenderer] { orderedOverlays.map(\.renderer) }

    var displays: [RainDisplay] {
        NSScreen.screens.map {
            RainDisplay(id: $0.stableDisplayID, name: $0.localizedName,
                        builtIn: CGDisplayIsBuiltin($0.displayID) != 0,
                        isMain: $0.displayID == CGMainDisplayID(), excluded: $0.displayID == excludedDisplayID)
        }
    }

    var targetScreens: [NSScreen] {
        let targets = Set(selection.targets(in: displays).map(\.id))
        return NSScreen.screens.filter { targets.contains($0.stableDisplayID) && $0.displayID != excludedDisplayID }
    }

    /// Prepare additions before removing any working windows. Retained screens keep their simulation.
    func reconcile(restoredGlyphs: Bool, transparent: Bool, hiddenFromCapture: Bool,
                   suspended: Bool, configure: (RainRenderer) -> Void) throws {
        let targets = targetScreens
        var additions: [String: Overlay] = [:]
        do {
            for screen in targets where overlays[screen.stableDisplayID]?.displayID != screen.displayID {
                let view = MTKView(frame: NSRect(origin: .zero, size: screen.frame.size))
                let renderer = try RainRenderer(view: view, restoredGlyphs: restoredGlyphs, transparentBackground: transparent)
                configure(renderer)
                let window = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                     backing: .buffered, defer: false, screen: screen)
                window.title = "Dreams Rain · \(screen.localizedName)"
                window.isReleasedWhenClosed = false
                window.level = .screenSaver
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
                window.ignoresMouseEvents = true
                window.sharingType = hiddenFromCapture ? .none : .readOnly
                window.isOpaque = !transparent
                window.backgroundColor = transparent ? .clear : .black
                window.hasShadow = false
                window.contentView = view
                additions[screen.stableDisplayID] = Overlay(displayID: screen.displayID, window: window, renderer: renderer)
            }
        } catch {
            additions.values.forEach { $0.close() }
            throw error
        }
        let targetIDs = Set(targets.map(\.stableDisplayID))
        for id in Array(overlays.keys) where !targetIDs.contains(id) || additions[id] != nil {
            overlays.removeValue(forKey: id)?.close()
        }
        overlays.merge(additions) { _, new in new }
        for screen in targets {
            guard let overlay = overlays[screen.stableDisplayID] else { continue }
            overlay.window.setFrame(screen.frame, display: true)
            if !suspended { overlay.window.orderFrontRegardless() }
        }
    }

    func close() {
        overlays.values.forEach { $0.close() }
        overlays.removeAll()
    }
}
