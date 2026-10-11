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
        let window: RainOverlayWindow
        let renderer: RainRenderer

        func close() {
            window.close()
        }
    }

    var selection = RainDisplaySelection.load()
    var excludedDisplayID: CGDirectDisplayID?
    private(set) var overlays: [String: Overlay] = [:]
    private var hasPresented = false
    private var returnApplication: NSRunningApplication?
    private weak var returnWindow: NSWindow?
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
                   suspended: Bool, configure: (RainRenderer) -> Void,
                   onEscape: @escaping () -> Void, onExit: @escaping () -> Void) throws {
        let targets = targetScreens
        let oldKey = overlays.first { $0.value.window.isKeyWindow }?.key
        let hadAppFocus = NSApplication.shared.isActive
        var additions: [String: Overlay] = [:]
        do {
            for screen in targets where overlays[screen.stableDisplayID]?.displayID != screen.displayID {
                let view = MTKView(frame: NSRect(origin: .zero, size: screen.frame.size))
                let renderer = try RainRenderer(view: view, restoredGlyphs: restoredGlyphs, transparentBackground: transparent)
                configure(renderer)
                let window = RainOverlayWindow(frame: screen.frame, metalView: view,
                    transparent: transparent, onEscape: onEscape, onExit: onExit)
                window.title = "Dreams Rain · \(screen.localizedName)"
                window.sharingType = hiddenFromCapture ? .none : .readOnly
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
        // Only the initial presentation and removal of our key window take focus.
        // A user working on an uncovered display must keep their application's Esc.
        let replacingKey = oldKey.map { !targetIDs.contains($0) || additions[$0] != nil } ?? false
        if !transparent, !suspended, !targets.isEmpty, !hasPresented || (replacingKey && hadAppFocus) {
            if !hasPresented {
                returnApplication = NSWorkspace.shared.frontmostApplication
                returnWindow = hadAppFocus ? NSApplication.shared.keyWindow : nil
            }
            let screen = targets.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
                ?? targets.first { $0.displayID == CGMainDisplayID() } ?? targets[0]
            let window = overlays[screen.stableDisplayID]!.window
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
        if !targets.isEmpty { hasPresented = true }
    }

    func close() {
        let ownedFocus = NSApplication.shared.isActive && overlays.values.contains { $0.window.isKeyWindow }
        overlays.values.forEach { $0.close() }
        overlays.removeAll()
        if ownedFocus {
            if let returnWindow, returnWindow.isVisible { returnWindow.makeKeyAndOrderFront(nil) }
            else if let returnApplication, returnApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                returnApplication.activate(options: [])
            }
        }
        hasPresented = false
        returnApplication = nil
        returnWindow = nil
    }
}
