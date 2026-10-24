import SwiftUI

struct ClockPage: View {
    let tuning: RainTuning
    let isActive: Bool
    var acceptsInput = true
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
                        .accessibilityLabel(Text(tuning.showsClock ? "clock.accessibility" : "rain.accessibility"))
                        .accessibilityValue(tuning.showsClock ? Text(timeline.date, style: .time) : Text(""))
                        .focusable(isActive && acceptsInput)
                        .onTapGesture { if acceptsInput { openSettings() } }
                        .onPlayPauseCommand { if acceptsInput { openSettings() } }
                }
            }
        }
        .ignoresSafeArea()
    }
}
