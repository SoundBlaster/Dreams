import AppKit
import Carbon

@main
struct HotkeyChecks {
    static func event(_ code: Int, _ chars: String, _ flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0,
                         context: nil, characters: chars, charactersIgnoringModifiers: chars, isARepeat: false,
                         keyCode: UInt16(code))!
    }

    static func main() {
        let standard = StopHotkey.standard
        precondition(standard.display == "⌃⌥⌘D", "default shortcut shows as \(standard.display)")
        precondition(standard.menuEquivalent?.key == "d"
            && standard.menuEquivalent?.flags == [.control, .option, .command], "menu equivalent of the default")

        // Recording: needs ⌃, ⌥ or ⌘; Esc and bare or shift-only keys are refused.
        precondition(StopHotkey(event: event(kVK_ANSI_X, "x", [])) == nil, "a bare key must be refused")
        precondition(StopHotkey(event: event(kVK_ANSI_X, "X", [.shift])) == nil, "shift alone must be refused")
        precondition(StopHotkey(event: event(kVK_Escape, "\u{1b}", [.command])) == nil, "Esc must be refused")
        let combo = StopHotkey(event: event(kVK_ANSI_X, "x", [.command, .shift]))
        precondition(combo?.display == "⇧⌘X" && combo?.keyCode == UInt32(kVK_ANSI_X), "recorded \(String(describing: combo?.display))")
        precondition(combo?.modifiers == UInt32(cmdKey | shiftKey), "carbon modifiers")
        let space = StopHotkey(event: event(kVK_Space, " ", [.control, .option]))
        precondition(space?.display == "⌃⌥Space" && space?.menuEquivalent == nil, "named key, no menu equivalent")
        let f5 = StopHotkey(event: event(kVK_F5, "\u{f708}", [.control]))
        precondition(f5?.display == "⌃F5", "function key name \(String(describing: f5?.display))")

        // Persistence, including garbage in the defaults.
        let suite = UserDefaults(suiteName: "ru.egormerkushev.dreams-hotkey-test")!
        suite.removePersistentDomain(forName: "ru.egormerkushev.dreams-hotkey-test")
        precondition(StopHotkey.load(from: suite) == standard, "empty defaults give the standard shortcut")
        combo!.save(to: suite)
        precondition(StopHotkey.load(from: suite) == combo, "save and load round trip")
        suite.set(999, forKey: "stopHotkeyKeyCode")
        precondition(StopHotkey.load(from: suite) == standard, "an invalid key code falls back")
        suite.set(Int(shiftKey), forKey: "stopHotkeyModifiers"); suite.set(5, forKey: "stopHotkeyKeyCode")
        precondition(StopHotkey.load(from: suite) == standard, "shift-only modifiers fall back")
        suite.removePersistentDomain(forName: "ru.egormerkushev.dreams-hotkey-test")
        print("PASS: default, recording rules, display names, menu equivalent, persistence and fallbacks")
    }
}
