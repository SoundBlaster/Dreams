import SwiftUI
import UIKit

private enum SettingsField: Hashable {
    case automatic, columns, density, brightness, speed, fade, search, braking, acceleration
    case spread, pulse, glow, red, green, blue, glyphs, clock, floating, typeface, size, done
}

struct SettingsPage: View {
    @Bindable var settings: RainSettings
    @Binding var previewPlays: Bool
    @State private var confirmsReset = false
    let close: () -> Void
    @FocusState private var focusedField: SettingsField?

    var body: some View {
        List {
            Section {
                Text("settings.hint").font(.callout).foregroundStyle(.secondary)
                Toggle("settings.preview", isOn: $previewPlays)
                Button("settings.done", action: close).focused($focusedField, equals: .done)
            } header: { Text("settings.title") }
            grid
            motion
            appearance
            clock
            Section("settings.advanced") {
                Toggle("settings.fps", isOn: $settings.tuning.showsFPS)
                    .accessibilityIdentifier("dreams.show-fps")
                Text("settings.fps.hint").font(.callout).foregroundStyle(.secondary)
            }
            Section {
                Button("settings.reset", role: .destructive) { confirmsReset = true }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIFocusSystem.movementDidFailNotification)) { notification in
            guard !confirmsReset,
                  let context = notification.userInfo?[UIFocusSystem.focusUpdateContextUserInfoKey] as? UIFocusUpdateContext
            else { return }
            // A row has no horizontal focus neighbour. The focus engine reports both
            // touch-surface swipes and directional presses through this native path.
            if context.focusHeading == .left { adjustFocused(by: -1) }
            if context.focusHeading == .right { adjustFocused(by: 1) }
        }
        // Keep room for tvOS focus expansion outside the List's layout bounds.
        .scrollClipDisabled()
        .padding(24)
        .frame(maxWidth: 1100)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(Color(red: settings.tuning.color.red, green: settings.tuning.color.green, blue: settings.tuning.color.blue))
        .preferredColorScheme(.dark)
        .defaultFocus($focusedField, .automatic)
        .task { focusedField = .automatic }
        .onExitCommand(perform: close)
        .onPlayPauseCommand(perform: close)
        .confirmationDialog("settings.reset.confirm", isPresented: $confirmsReset) {
            Button("settings.reset", role: .destructive) { settings.reset() }
            Button("settings.cancel", role: .cancel) {}
        }
    }

    private var grid: some View {
        Section("settings.grid") {
            Toggle("settings.automatic", isOn: $settings.tuning.automaticColumns)
                .focused($focusedField, equals: .automatic)
            AdjustmentRow(title: "settings.columns", value: "\(settings.tuning.columns)", focus: $focusedField, field: .columns) {
                settings.tuning.columns += $0
            }.disabled(settings.tuning.automaticColumns)
            adjustment("settings.density", value: $settings.tuning.density, step: 0.01, field: .density)
        }
    }

    private var motion: some View {
        Section("settings.motion") {
            adjustment("settings.speed", value: $settings.tuning.speed, step: 0.01, field: .speed,
                       readout: settings.tuning.speed.formatted(.number.precision(.fractionLength(2))) + "×")
            adjustment("settings.fade", value: $settings.tuning.fade, step: 1, field: .fade,
                       readout: settings.tuning.fade.formatted(.number.precision(.fractionLength(0))))
            adjustment("settings.search", value: $settings.tuning.searchFraction, step: 0.01, field: .search,
                       hint: "settings.search.hint")
            Toggle("settings.braking", isOn: $settings.tuning.decelerationEnabled)
                .focused($focusedField, equals: .braking)
            adjustment("settings.acceleration", value: $settings.tuning.acceleration, step: 0.5, field: .acceleration,
                       readout: settings.tuning.acceleration.formatted(.number.precision(.fractionLength(1))))
                .disabled(!settings.tuning.decelerationEnabled)
        }
    }

    private var appearance: some View {
        Section("settings.appearance") {
            adjustment("settings.brightness", value: $settings.tuning.brightness, step: 0.01, field: .brightness)
            adjustment("settings.spread", value: $settings.tuning.brightnessSpread, step: 0.01, field: .spread)
            adjustment("settings.pulse", value: $settings.tuning.pulseStrength, step: 0.01, field: .pulse)
            adjustment("settings.glow", value: $settings.tuning.glow, step: 0.01, field: .glow)
            adjustment("settings.red", value: $settings.tuning.color.red, step: 0.01, field: .red)
            adjustment("settings.green", value: $settings.tuning.color.green, step: 0.01, field: .green)
            adjustment("settings.blue", value: $settings.tuning.color.blue, step: 0.01, field: .blue)
            Toggle("settings.glyphs", isOn: $settings.tuning.restoredGlyphs).focused($focusedField, equals: .glyphs)
        }
    }

    private var clock: some View {
        Section("settings.clock") {
            Toggle("settings.clock.visible", isOn: $settings.tuning.showsClock).focused($focusedField, equals: .clock)
            Toggle("settings.floating", isOn: $settings.tuning.floatingClock).focused($focusedField, equals: .floating)
                .disabled(!settings.tuning.showsClock)
            AdjustmentRow(title: "settings.typeface", value: String(localized: String.LocalizationValue(settings.tuning.clockTypeface.titleKey)),
                          focus: $focusedField, field: .typeface) { direction in
                let fonts = ClockTypeface.allCases
                let index = fonts.firstIndex(of: settings.tuning.clockTypeface) ?? 0
                settings.tuning.clockTypeface = fonts[(index + direction + fonts.count) % fonts.count]
            }.disabled(!settings.tuning.showsClock)
            adjustment("settings.size", value: $settings.tuning.clockSize, step: 0.05, field: .size)
                .disabled(!settings.tuning.showsClock)
        }
    }

    /// Native List focuses its cell; horizontal focus movement adjusts that row's value.
    private func adjustFocused(by direction: Int) {
        if focusedField == .columns {
            if !settings.tuning.automaticColumns { settings.tuning.columns += direction }
            return
        }
        if focusedField == .typeface {
            let fonts = ClockTypeface.allCases
            let index = fonts.firstIndex(of: settings.tuning.clockTypeface) ?? 0
            settings.tuning.clockTypeface = fonts[(index + direction + fonts.count) % fonts.count]
            return
        }
        let parameter: (WritableKeyPath<RainTuning, Double>, Double)? = switch focusedField {
        case .density: (\.density, 0.01)
        case .brightness: (\.brightness, 0.01)
        case .speed: (\.speed, 0.01)
        case .fade: (\.fade, 1)
        case .search: (\.searchFraction, 0.01)
        case .acceleration: (\.acceleration, 0.5)
        case .spread: (\.brightnessSpread, 0.01)
        case .pulse: (\.pulseStrength, 0.01)
        case .glow: (\.glow, 0.01)
        case .red: (\.color.red, 0.01)
        case .green: (\.color.green, 0.01)
        case .blue: (\.color.blue, 0.01)
        case .size: (\.clockSize, 0.05)
        default: nil
        }
        if let (keyPath, step) = parameter { settings.tuning[keyPath: keyPath] += Double(direction) * step }
    }

    private func adjustment(_ title: LocalizedStringKey, value: Binding<Double>, step: Double, field: SettingsField,
                            readout: String? = nil, hint: LocalizedStringKey = "settings.adjust.hint") -> some View {
        AdjustmentRow(title: title, value: readout ?? value.wrappedValue.formatted(.percent.precision(.fractionLength(0))),
                      hint: hint, focus: $focusedField, field: field) {
            value.wrappedValue += Double($0) * step
        }
    }
}

/// tvOS has no system Slider. Native focusable buttons expose remote and VoiceOver adjustment.
private struct AdjustmentRow: View {
    let title: LocalizedStringKey
    let value: String
    var hint: LocalizedStringKey = "settings.adjust.hint"
    var focus: FocusState<SettingsField?>.Binding
    let field: SettingsField
    let adjust: (Int) -> Void

    var body: some View {
        Button { adjust(1) } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.left").accessibilityHidden(true)
                Text(value).monospacedDigit().frame(minWidth: 180)
                Image(systemName: "chevron.right").accessibilityHidden(true)
            }
        }
        .focused(focus, equals: field)
        .accessibilityIdentifier("dreams.tv.settings.\(field)")
        .accessibilityLabel(Text(title))
        .accessibilityValue(value)
        .accessibilityHint(Text(hint))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjust(1)
            case .decrement: adjust(-1)
            @unknown default: break
            }
        }
    }
}
