import SwiftUI

struct ClockPage: View {
    let tuning: RainTuning
    let isActive: Bool
    let openSettings: () -> Void
    @State private var renderingFailed = false

    var body: some View {
        ZStack {
            Color.black
            if renderingFailed {
                VStack(spacing: 24) {
                    Text("render.unavailable").font(.title)
                    Button("settings.title", action: openSettings)
                }
            } else {
                TimelineView(.everyMinute) { timeline in
                    MatrixSurface(tuning: tuning, isActive: isActive) { renderingFailed = true }
                        .accessibilityLabel(Text("clock.accessibility"))
                        .accessibilityValue(Text(timeline.date, style: .time))
                        .focusable(isActive)
                        .onTapGesture(perform: openSettings)
                        .onPlayPauseCommand(perform: openSettings)
                }
            }
        }
        .ignoresSafeArea()
    }
}
