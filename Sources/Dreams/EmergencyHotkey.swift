import Carbon

/// Carbon hotkeys do not require monitoring or recording all keyboard input.
@MainActor
final class EmergencyHotkey {
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    func install(controller: DreamsController) -> Bool {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                  eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(controller).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<DreamsController>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in controller.stop() }
            return noErr
        }, 1, &event, context, &handler)
        guard installed == noErr else { return false }
        let identifier = EventHotKeyID(signature: 0x44524D53, id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_ANSI_D),
            UInt32(controlKey | optionKey | cmdKey), identifier,
            GetApplicationEventTarget(), 0, &hotkey)
        if registered != noErr { uninstall() }
        return registered == noErr
    }

    func uninstall() {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
        hotkey = nil
        handler = nil
    }
}
