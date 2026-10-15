import AppKit
import Observation

/// One temporary, window-scoped capture shared by both settings presentations.
@MainActor
@Observable
final class StopShortcutRecorder {
    private(set) var isRecording = false
    var message: String?
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var commit: ((StopHotkey) -> Void)?
    @ObservationIgnored var onChange: (() -> Void)?

    isolated deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func start(in window: NSWindow, commit: @escaping (StopHotkey) -> Void) {
        cancel()
        self.window = window
        self.commit = commit
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
        // Losing this window, app focus, or closing it must never leave a keyboard trap.
        for name in [NSWindow.willCloseNotification, NSWindow.didResignKeyNotification] {
            observe(name, object: window)
        }
        for name in [NSApplication.didResignActiveNotification, NSApplication.didHideNotification] {
            observe(name, object: NSApplication.shared)
        }
        onChange?()
    }

    private func observe(_ name: Notification.Name, object: AnyObject) {
        observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.cancel() }
        })
    }

    /// Returns nil only for a key consumed by this recording session.
    func handle(_ event: NSEvent) -> NSEvent? {
        guard isRecording, let window, event.window === window else { return event }
        if event.keyCode == 53 {
            cancel()
        } else if let shortcut = StopHotkey(event: event) {
            let apply = commit
            cancel()
            apply?(shortcut)
        } else {
            message = L("hotkey.invalid")
            onChange?()
            NSSound.beep()
        }
        return nil
    }

    func cancel() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        window = nil
        commit = nil
        isRecording = false
        message = nil
        onChange?()
    }
}
