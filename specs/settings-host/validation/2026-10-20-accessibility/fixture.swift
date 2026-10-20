import AppKit
import SwiftUI

struct AXFixture: View {
    @State private var stringHelp = 0.43
    @State private var textHelp = 0.43
    @State private var hint = 0.43
    @State private var rowHelp = 0.43
    @State private var plain = 0.43
    var body: some View {
        VStack(spacing: 24) {
            Slider(value: .constant(0.43), in: 0.25...3) { Text("Native without help") }
                .accessibilityIdentifier("dreams.probe.native-plain")
            Slider(value: $stringHelp, in: 0.25...3) { Text("Native String help") }
                .help("String tooltip").accessibilityIdentifier("dreams.probe.string")
            Slider(value: $textHelp, in: 0.25...3) { Text("Native Text help") }
                .help(Text("Text tooltip")).accessibilityIdentifier("dreams.probe.text")
            Slider(value: $hint, in: 0.25...3) { Text("Native hint") }
                .accessibilityHint("Spoken hint").accessibilityIdentifier("dreams.probe.hint")
            SettingsSliderRow("Row help", value: $rowHelp, in: 0.25...3, step: 0.01,
                              readout: "0.43×", identifier: "dreams.probe.row", help: "Row tooltip")
            SettingsSliderRow("No help", value: $plain, in: 0.25...3, step: 0.01,
                              readout: "0.43×", identifier: "dreams.probe.plain")
        }.padding(24).frame(width: 650, height: 420)
    }
}

@main @MainActor struct AXFixtureApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 650, height: 420),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Dreams AX comparison"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AXFixture())
        window.orderFront(nil)
        print("AX_FIXTURE_PID=\(ProcessInfo.processInfo.processIdentifier)")
        fflush(stdout)
        app.run()
    }
}
