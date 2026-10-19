import DreamsSettingsUI
import SwiftUI

struct NativePreviewPane: View {
    @Bindable var session: RainPreviewSession

    var body: some View {
        VStack(alignment: .leading) {
            playbackButton
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer(minLength: 0)
            if let error = session.errorMessage {
                SettingsMaterialPanel {
                    VStack {
                        Label(settingsString("native.preview.unavailable"), systemImage: "exclamationmark.triangle")
                        Text(error).font(.caption).foregroundStyle(.secondary)
                        Button(settingsString("native.preview.retry")) { session.refresh() }
                    }
                    .padding()
                }
                Spacer(minLength: 0)
            }
            SettingsMaterialPanel {
                Text(settingsString("native.preview.help"))
                    .font(.caption).foregroundStyle(.secondary).padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var playbackButton: some View {
        if #available(macOS 26.0, *) {
            playbackAction.buttonStyle(.glassProminent)
        } else {
            playbackAction.buttonStyle(.borderedProminent)
        }
    }

    private var playbackAction: some View {
        Button {
            session.isPlaying.toggle()
        } label: {
            Label(session.isPlaying ? settingsString("native.preview.pause") : settingsString("native.preview.play"),
                  systemImage: session.isPlaying ? "pause.fill" : "play.fill")
                .labelStyle(.iconOnly)
                .frame(width: 64, height: 28)
        }
        .controlSize(.large)
        .disabled(session.errorMessage != nil)
        .accessibilityIdentifier("dreams.native.preview-playback")
    }
}
