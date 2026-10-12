import SwiftUI

private enum SettingsField: Hashable {
    case columns, brightness, speed, fade, floating, typeface, size, done
}

struct SettingsPage: View {
    @Bindable var settings: RainSettings
    let close: () -> Void
    @FocusState private var focusedField: SettingsField?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("settings.title").font(.largeTitle.weight(.semibold)).padding(.bottom, 8)
            AdjustmentRow(title: "settings.columns", value: "\(settings.tuning.columns)", focus: $focusedField, field: .columns) { direction in
                settings.tuning.columns += direction * 4
            }
            AdjustmentRow(title: "settings.brightness", value: settings.tuning.brightness.formatted(.percent.precision(.fractionLength(0))),
                          focus: $focusedField, field: .brightness) {
                settings.tuning.brightness += Double($0) * 0.01
            }
            AdjustmentRow(title: "settings.speed", value: "\(settings.tuning.speed.formatted(.number.precision(.fractionLength(2))))×",
                          focus: $focusedField, field: .speed) {
                settings.tuning.speed += Double($0) * 0.05
            }
            AdjustmentRow(title: "settings.fade", value: settings.tuning.fade.formatted(.number.precision(.fractionLength(0))),
                          focus: $focusedField, field: .fade) {
                settings.tuning.fade += Double($0)
            }
            AdjustmentRow(title: "settings.floating", value: String(localized: settings.tuning.floatingClock ? "settings.on" : "settings.off"),
                          focus: $focusedField, field: .floating) { _ in
                settings.tuning.floatingClock.toggle()
            }
            AdjustmentRow(title: "settings.typeface", value: NSLocalizedString(settings.tuning.clockTypeface.titleKey, comment: ""),
                          focus: $focusedField, field: .typeface) { direction in
                let fonts = ClockTypeface.allCases
                let index = fonts.firstIndex(of: settings.tuning.clockTypeface) ?? 0
                settings.tuning.clockTypeface = fonts[(index + direction + fonts.count) % fonts.count]
            }
            AdjustmentRow(title: "settings.size", value: settings.tuning.clockSize.formatted(.percent.precision(.fractionLength(0))),
                          focus: $focusedField, field: .size) {
                settings.tuning.clockSize += Double($0) * 0.05
            }
            Text("settings.hint").font(.callout).foregroundStyle(.secondary).padding(.top, 4)
            Button("settings.done", action: close).padding(.top, 8).focused($focusedField, equals: .done)
        }
        .frame(maxWidth: 950, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.035))
        .preferredColorScheme(.dark)
        .defaultFocus($focusedField, .columns)
        .task { focusedField = .columns }
        .onExitCommand(perform: close)
    }
}

private struct AdjustmentRow: View {
    let title: LocalizedStringKey
    let value: String
    var focus: FocusState<SettingsField?>.Binding
    let field: SettingsField
    let adjust: (Int) -> Void

    private var focused: Bool { focus.wrappedValue == field }

    var body: some View {
        Button { adjust(1) } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.left").font(.body)
                Text(value).monospacedDigit().frame(minWidth: 210)
                Image(systemName: "chevron.right").font(.body)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(focused ? Color(white: 0.18) : Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(focused ? Color.green.opacity(0.8) : .clear, lineWidth: 3))
        }
        .buttonStyle(.plain)
        .focusable()
        .focused(focus, equals: field)
        .onMoveCommand { direction in
            if direction == .left { adjust(-1) }
            if direction == .right { adjust(1) }
        }
        .accessibilityLabel(Text(title))
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjust(1)
            case .decrement: adjust(-1)
            @unknown default: break
            }
        }
    }
}
