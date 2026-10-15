import DreamsSettingsUI
import SwiftUI

struct NativePreviewPane: View {
    @Bindable var session: RainPreviewSession

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(settingsString("native.preview.title")).font(.headline)
                Spacer()
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
            SettingsPreviewRegion {
                ZStack {
                    RainPreviewSurface(session: session)
                    if let error = session.errorMessage {
                        VStack {
                            Label(settingsString("native.preview.unavailable"), systemImage: "exclamationmark.triangle")
                            Text(error).font(.caption).foregroundStyle(.secondary)
                            Button(settingsString("native.preview.retry")) { session.refresh() }
                        }
                        .padding()
                    }
                }
                .background(.background.secondary)
            }
            Text(settingsString("native.preview.help"))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }
}
