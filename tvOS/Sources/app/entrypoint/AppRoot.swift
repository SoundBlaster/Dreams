import SwiftUI

struct AppRoot: View {
    @State private var settings = RainSettings()
    @State private var showsSettings = false
    @State private var previewPlays = true
    @Environment(\.scenePhase) private var scenePhase

    private var clockIsActive: Bool { scenePhase == .active && !showsSettings }

    var body: some View {
        ZStack {
            ClockPage(tuning: settings.tuning, isActive: scenePhase == .active && (!showsSettings || previewPlays),
                      acceptsInput: !showsSettings) { showsSettings = true }
                .allowsHitTesting(!showsSettings)
                .accessibilityHidden(showsSettings)
            if showsSettings {
                SettingsPage(settings: settings, previewPlays: $previewPlays) { showsSettings = false }
            }
        }
        .onExitCommand { showsSettings.toggle() }
        .onChange(of: clockIsActive, initial: true) { _, active in
            UIApplication.shared.isIdleTimerDisabled = active
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}
