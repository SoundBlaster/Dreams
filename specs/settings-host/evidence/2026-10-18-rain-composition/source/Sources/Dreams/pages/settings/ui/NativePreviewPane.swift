import DreamsSettingsUI
import SwiftUI

struct NativePreviewPane: View {
    @Bindable var session: RainPreviewSession
    var outlined = false

    var body: some View {
        VStack(alignment: .leading) {
            SettingsMaterialPanel {
                HStack {
                    Text(settingsString("native.preview.title")).font(.headline)
                    Spacer()
                    playbackButton
                }
                .padding(12)
            }
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
            }
        }
        .padding(outlined ? 12 : 0)
        .overlay {
            if outlined {
                RoundedRectangle(cornerRadius: 16).strokeBorder(.separator)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder private var playbackButton: some View {
        if #available(macOS 26.0, *) {
            playbackAction.buttonStyle(.glass)
        } else {
            playbackAction.buttonStyle(.bordered)
        }
    }

    private var playbackAction: some View {
        Button {
            session.isPlaying.toggle()
        } label: {
            Label(session.isPlaying ? settingsString("native.preview.pause") : settingsString("native.preview.play"),
                  systemImage: session.isPlaying ? "pause.fill" : "play.fill")
        }
        .labelStyle(.iconOnly)
        .disabled(session.errorMessage != nil)
        .accessibilityIdentifier("dreams.native.preview-playback")
    }
}
