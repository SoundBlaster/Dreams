import AppKit
import Carbon

/// The global shortcut that stops the rain. A Carbon hotkey needs no input monitoring permission.
struct StopHotkey: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon: controlKey, optionKey, shiftKey, cmdKey
    var key: String        // how the key is shown

    static let standard = StopHotkey(keyCode: UInt32(kVK_ANSI_D),
                                     modifiers: UInt32(controlKey | optionKey | cmdKey), key: "D")

    private static let names: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    var display: String {
        (modifiers & UInt32(controlKey) != 0 ? "⌃" : "") + (modifiers & UInt32(optionKey) != 0 ? "⌥" : "")
            + (modifiers & UInt32(shiftKey) != 0 ? "⇧" : "") + (modifiers & UInt32(cmdKey) != 0 ? "⌘" : "") + key
    }

    /// A shortcut from a key press: it needs ⌃, ⌥ or ⌘, so a plain key can never be taken over.
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection([.control, .option, .shift, .command])
        guard !flags.intersection([.control, .option, .command]).isEmpty, Int(event.keyCode) != kVK_Escape else { return nil }
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        guard let name = Self.names[Int(event.keyCode)]
                ?? event.charactersIgnoringModifiers?.uppercased().trimmingCharacters(in: .whitespaces),
              !name.isEmpty else { return nil }
        self.init(keyCode: UInt32(event.keyCode), modifiers: carbon, key: name)
    }

    init(keyCode: UInt32, modifiers: UInt32, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    static func load(from defaults: UserDefaults = .standard) -> StopHotkey {
        guard let code = defaults.object(forKey: "stopHotkeyKeyCode") as? Int,
              let modifiers = defaults.object(forKey: "stopHotkeyModifiers") as? Int,
              let key = defaults.string(forKey: "stopHotkeyKey"), !key.isEmpty,
              (0...127).contains(code), modifiers & (controlKey | optionKey | cmdKey) != 0 else { return .standard }
        return StopHotkey(keyCode: UInt32(code), modifiers: UInt32(modifiers), key: key)
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(Int(keyCode), forKey: "stopHotkeyKeyCode")
        defaults.set(Int(modifiers), forKey: "stopHotkeyModifiers")
        defaults.set(key, forKey: "stopHotkeyKey")
    }

    /// The same shortcut for the menu item ("Stop Animation"), when the key is a plain character.
    var menuEquivalent: (key: String, flags: NSEvent.ModifierFlags)? {
        guard key.count == 1, Self.names.values.contains(key) == false else { return nil }
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if modifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if modifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if modifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        return (key.lowercased(), flags)
    }
}
