import AppKit

/// A separate process owns the test monitor, so the real Dreams process receives WindowServer events.
@main
enum DisplayHost {
    @MainActor
    static func main() throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let display = try DreamsVirtualDisplay(width: 800, height: 600)
        FileHandle.standardInput.readabilityHandler = { input in
            if input.availableData.isEmpty {
                Task { @MainActor in NSApplication.shared.terminate(nil) }
            }
        }
        Task { @MainActor in
            do { try await announce(display); return }
            catch { FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8)) }
            application.terminate(nil)
        }
        withExtendedLifetime(display) { application.run() }
    }

    @MainActor
    private static func announce(_ display: DreamsVirtualDisplay) async throws {
        for _ in 0..<50 {
            if NSScreen.screens.contains(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == display.displayID
            }) {
                let data = try JSONSerialization.data(withJSONObject: ["display_id": Int(display.displayID)])
                FileHandle.standardOutput.write(data + Data("\n".utf8))
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        FileHandle.standardError.write(Data("Test display did not appear in AppKit.\n".utf8))
    }
}
