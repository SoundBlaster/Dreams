import Carbon

/// Carbon hotkeys do not require monitoring or recording all keyboard input.
@MainActor
final class EmergencyHotkey {
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    private var current: StopHotkey?

    func install(controller: DreamsController, hotkey: StopHotkey) -> Bool {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                  eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(controller).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<DreamsController>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in controller.stop(reason: .hotkey) }
            return noErr
        }, 1, &event, context, &handler)
        guard installed == noErr else { return false }
        guard register(hotkey) else { uninstall(); return false }
        return true
    }

    /// Switches to another shortcut. If it cannot be registered (taken by another app), the old one stays.
    func change(to hotkey: StopHotkey) -> Bool {
        let previous = current
        if let existing = self.hotkey { UnregisterEventHotKey(existing); self.hotkey = nil }
        if register(hotkey) { return true }
        if let previous { _ = register(previous) }
        return false
    }

    private func register(_ hotkey: StopHotkey) -> Bool {
        let identifier = EventHotKeyID(signature: 0x44524D53, id: 1)
        let registered = RegisterEventHotKey(hotkey.keyCode, hotkey.modifiers, identifier,
                                             GetApplicationEventTarget(), 0, &self.hotkey)
        if registered == noErr { current = hotkey }
        return registered == noErr
    }

    func uninstall() {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
        hotkey = nil
        handler = nil
    }
}
