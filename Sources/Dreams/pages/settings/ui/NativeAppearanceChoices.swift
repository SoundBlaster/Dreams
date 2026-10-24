import SwiftUI

struct NativeAppearanceChoices: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Section {
            ViewThatFits(in: .horizontal) {
                HStack { choices }
                VStack(alignment: .leading) { choices }
            }
        } header: {
            Text(settingsString("appearance.style"))
        } footer: {
            Text(model.appearancePreset == nil ? settingsString("appearance.custom") : settingsString("appearance.help"))
                .accessibilityIdentifier("dreams.appearance-status")
        }
    }

    private var choices: some View {
        ForEach(NativeAppearancePreset.allCases) { preset in
            Toggle(isOn: Binding(get: { model.appearancePreset == preset }, set: { selected in
                if selected { model.applyAppearance(preset) }
            })) {
                Text(preset.title).frame(maxWidth: .infinity)
            }
            .toggleStyle(.button)
            .accessibilityIdentifier("dreams.appearance-preset." + preset.rawValue)
            .help(settingsString("appearance.help"))
        }
    }
}

struct NativeRainPalette: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settingsString("palette.title")).font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 44))], alignment: .leading, spacing: 8) {
                ForEach(NativeRainSwatch.allCases) { swatch in
                    Button { model.applyColor(swatch) } label: {
                        Circle().fill(Color(nsColor: swatch.color))
                            .overlay {
                                if model.isSelected(swatch) {
                                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.black)
                                }
                            }
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(swatch.title)
                    .accessibilityAddTraits(model.isSelected(swatch) ? .isSelected : [])
                    .accessibilityIdentifier("dreams.rain-palette." + swatch.rawValue)
                    .help(swatch.title)
                }
            }
        }
    }
}
