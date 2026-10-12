import AppKit
import ScreenerKit
import Testing
import VirtualDisplayBridge
@testable import Dreams

/// Opt-in WindowServer checks: creates and removes a temporary second display.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["DREAMS_TEST_EXIT"] == "1"))
@MainActor
struct OverlayExitTests {
    @Test func escapeButtonAndDisplayFocusLifecycle() async throws {
        let application = NSApplication.shared
        let previousApplication = NSWorkspace.shared.frontmostApplication
        application.setActivationPolicy(.regular)
        let (start, started) = AsyncStream<Void>.makeStream()
        let scenario = Task<Result<Void, any Error>, Never> { @MainActor in
            for await _ in start { break }
            let result: Result<Void, any Error>
            do { try await verifyExitLifecycle(); result = .success(()) }
            catch { result = .failure(error) }
            application.stop(nil)
            if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
                timestamp: 0, windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0) {
                application.postEvent(event, atStart: true)
            }
            return result
        }
        // Enter AppKit from a run-loop block, not a MainActor dispatch job: the
        // native loop must be able to service the scenario's asynchronous jobs.
        await withCheckedContinuation { (finished: CheckedContinuation<Void, Never>) in
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue) {
                MainActor.assumeIsolated {
                    started.yield(())
                    started.finish()
                    application.run()
                    finished.resume()
                }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
        previousApplication?.activate(options: [])
        try await scenario.value.get()
    }

    private func verifyExitLifecycle() async throws {
        _ = try #require(ProcessInfo.processInfo.environment["DREAMS_FEED_DIRECTORY"])
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)
        let manager = RainScreenManager()
        manager.selection = .init(mode: .all)
        let probe = EscapeProbeWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                                      styleMask: [.titled], backing: .buffered, defer: false)
        probe.isReleasedWhenClosed = false
        probe.title = "Dreams Exit Test · Working Window"
        probe.makeKeyAndOrderFront(nil)
        var display: DreamsVirtualDisplay? = try DreamsVirtualDisplay(width: 800, height: 600)
        let displayID = try #require(display?.displayID)
        defer {
            manager.close()
            display = nil
            probe.close()
        }
        try await waitUntil { NSScreen.screens.contains { $0.displayID == displayID } && application.isActive }
        var escaped = 0
        var clicked = 0
        func reconcile(transparent: Bool = false) throws {
            try manager.reconcile(restoredGlyphs: true, transparent: transparent, hiddenFromCapture: false,
                suspended: false, configure: { $0.rainColumnCount = 48 },
                onEscape: { [weak manager] in escaped += 1; manager?.close() },
                onExit: { [weak manager] in clicked += 1; manager?.close() })
        }
        func escape(_ window: NSWindow) throws {
            let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53))
            window.sendEvent(event)
        }
        let recorder = Screener()
        let trace = try await recorder.startSession(name: "Dreams-overlay-exit",
            appBundleID: "ru.egormerkushev.dreams.exit-tests",
            tracesDirectory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "Screener/Traces"))
        let capture = ScreenerCaptureSession(screener: recorder)
        func checkpoint(_ name: String, view: NSView) async throws {
            view.layoutSubtreeIfNeeded()
            try await recorder.mark(name, metadata: ["backend": "AppKit controls; Metal verified separately"])
            try await capture.capture(from: AppKitCaptureSource(view: view), reason: name)
        }
        do {
            try reconcile()
            #expect(manager.overlays.count >= 2)
            let windows = manager.orderedOverlays.map(\.window)
            let key = try #require(windows.first { $0.isKeyWindow })
            #expect(windows.allSatisfy { $0.canBecomeKey && !$0.ignoresMouseEvents })
            let content = try #require(key.contentView as? RainOverlayContentView)
            #expect(!content.exitButton.isHidden)
            #expect(content.exitButton.accessibilityIdentifier() == "dreams.exit-overlay")
            try await checkpoint("01.OpaqueExitButton", view: content)
            content.revealExitControls(at: 10)
            content.hideExitControlsIfIdle(at: 13)
            #expect(!content.exitButton.isHidden)
            content.hideExitControlsIfIdle(at: 15)
            if !NSWorkspace.shared.isVoiceOverEnabled && !application.isFullKeyboardAccessEnabled {
                #expect(content.exitButton.isHidden)
            }
            content.revealExitControls()
            try await checkpoint("02.ControlsRevealed", view: content)
            try escape(key)
            #expect(escaped == 1 && manager.overlays.isEmpty)
            #expect(windows.allSatisfy { !$0.isVisible && $0.metalView.isPaused })
            #expect(probe.isKeyWindow, "Exit restores the window that started the opaque session")

            try reconcile()
            let buttonWindow = try #require(manager.orderedOverlays.first?.window)
            let buttonContent = try #require(buttonWindow.contentView as? RainOverlayContentView)
            let click = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 10, y: 10),
                modifierFlags: [], timestamp: 0, windowNumber: buttonWindow.windowNumber, context: nil,
                eventNumber: 1, clickCount: 1, pressure: 1))
            buttonContent.mouseDown(with: click)
            #expect(!manager.overlays.isEmpty && clicked == 0, "An ordinary click must not stop the rain")
            buttonContent.exitButton.performClick(nil)
            #expect(clicked == 1 && manager.overlays.isEmpty)

            try reconcile()
            let selectedID = try #require(manager.overlays.first { $0.value.displayID == displayID }?.key)
            manager.selection = .init(mode: .selected, selectedIDs: [selectedID])
            try reconcile()
            #expect(manager.overlays.count == 1)
            probe.makeKeyAndOrderFront(nil)
            try reconcile()
            #expect(probe.isKeyWindow, "Reconciliation must not take focus from work on a free display")
            try escape(probe)
            #expect(probe.escapeCount == 1 && !manager.overlays.isEmpty)
            let removedWindow = try #require(manager.orderedOverlays.first { $0.displayID == displayID }?.window)
            removedWindow.makeKeyAndOrderFront(nil)
            #expect(removedWindow.isKeyWindow)
            display = nil
            try await waitUntil { !NSScreen.screens.contains { $0.displayID == displayID } }
            try reconcile()
            #expect(!manager.overlays.isEmpty)
            let replacement = try #require(manager.orderedOverlays.first { $0.window.isKeyWindow }?.window)
            #expect(replacement !== removedWindow)
            try await checkpoint("03.UnplugFocusTransferred", view: try #require(replacement.contentView))
            manager.close()

            try reconcile(transparent: true)
            #expect(probe.isKeyWindow)
            #expect(manager.orderedOverlays.allSatisfy { !$0.window.canBecomeKey && $0.window.ignoresMouseEvents })
            #expect(manager.orderedOverlays.allSatisfy { !($0.window.contentView is RainOverlayContentView) })
            try escape(probe)
            #expect(probe.escapeCount == 2 && !manager.overlays.isEmpty && escaped == 1)
            manager.close()
            try await checkpoint("04.WorkingWindowRestored", view: try #require(probe.contentView))
            try await recorder.stopSession()
            print("DREAMS_EXIT_TRACE=\(trace.path)")
            print("PASS: multi-display Esc/button exit, plain click, focus restore, active-display unplug and transparent input")
        } catch {
            try? await recorder.mark("Scenario.failed", metadata: ["error": String(describing: error)])
            try? await recorder.stopSession()
            throw error
        }
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 8
        while !condition(), ProcessInfo.processInfo.systemUptime < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        try #require(condition(), "WindowServer state: displays=\(NSScreen.screens.map(\.displayID)), active=\(NSApplication.shared.isActive)")
    }
}

@MainActor
private final class EscapeProbeWindow: NSWindow {
    var escapeCount = 0
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { escapeCount += 1 }
        else { super.keyDown(with: event) }
    }
}
