import DreamsSettingsUI
import SwiftUI

struct NativeParameterRow: View {
    @Bindable var model: NativeSettingsModel
    let parameter: NativeRainParameter
    @Environment(\.locale) private var locale

    var body: some View {
        SettingsSliderRow(parameter.title, value: $model[parameter: parameter], in: parameter.range,
                          step: parameter.step, readout: parameter.readout(model[parameter: parameter], locale: locale),
                          identifier: parameter.identifier)
    }
}

struct NativeGeneralForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section {
                Text(model.activity).foregroundStyle(.secondary)
                    .accessibilityIdentifier("dreams.native.activity")
                HStack {
                    Button(settingsString("button.startMatrix")) { model.start() }
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("dreams.start-matrix")
                    Button(settingsString("button.stop")) { model.stop() }
                        .accessibilityIdentifier("dreams.stop")
                }
                Picker(settingsString("runtime.accessibility"), selection: $model.runTime) {
                    ForEach(DreamsPreset.runTimeChoices, id: \.self) { seconds in
                        Text(SettingsPageController.runTimeTitle(seconds)).tag(seconds)
                    }
                }
                .disabled(model.transparent).accessibilityIdentifier("dreams.run-time")
            }
            Section(settingsString("hotkey.label")) {
                LabeledContent { Text(model.stopShortcut).monospaced() } label: { Text(settingsString("hotkey.label")) }
                Text(L("native.escapeHint", model.stopShortcut)).foregroundStyle(.secondary)
                Button(settingsString("native.hotkeyLegacy")) { model.showLegacy() }
            }
        }
        .formStyle(.grouped)
    }
}

struct NativeAppearanceForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section(settingsString("label.color")) {
                ColorPicker(settingsString("rain.color.accessibility"), selection: $model.rainColor, supportsOpacity: false)
                    .accessibilityIdentifier("dreams.rain-color")
                NativeParameterRow(model: model, parameter: .glow)
                NativeParameterRow(model: model, parameter: .spread)
            }
            Section(settingsString("section.glyphs")) {
                Toggle(settingsString("check.restored"), isOn: $model.restoredGlyphs)
                    .accessibilityIdentifier("dreams.restored-glyphs")
            }
        }
        .formStyle(.grouped)
    }
}

struct NativeRainForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section(settingsString("rain.grid")) {
                Toggle(settingsString("rain.columns.auto"), isOn: $model.automaticColumns)
                    .accessibilityIdentifier("dreams.rain-columns-auto")
                SettingsSliderRow(settingsString("rain.columns"), value: $model.columns, in: 24...240, step: 1,
                                  readout: Int(model.columns).formatted(), identifier: "dreams.rain-columns")
                    .disabled(model.automaticColumns)
                NativeParameterRow(model: model, parameter: .density)
            }
            Section(settingsString("native.motion")) {
                NativeParameterRow(model: model, parameter: .speed)
                NativeParameterRow(model: model, parameter: .fade)
                Toggle(settingsString("rain.deceleration.enabled"), isOn: $model.decelerationEnabled)
                    .accessibilityIdentifier("dreams.rain-deceleration-enabled")
                NativeParameterRow(model: model, parameter: .deceleration).disabled(!model.decelerationEnabled)
            }
            Section(settingsString("rain.search")) {
                NativeParameterRow(model: model, parameter: .search)
                Text(settingsString("rain.search.tip")).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct NativeBackgroundForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section {
                Toggle(settingsString("check.transparent"), isOn: $model.transparent)
                    .accessibilityIdentifier("dreams.transparent-background")
                Text(settingsString("native.backgroundProfiles")).foregroundStyle(.secondary)
            }
            Section(settingsString("section.between")) {
                NativeParameterRow(model: model, parameter: .idle)
                Text(settingsString("rain.idle.tip")).foregroundStyle(.secondary)
            }
            Section {
                Toggle(settingsString("check.hideFromScreenshots"), isOn: $model.hideFromScreenshots)
                    .accessibilityIdentifier("dreams.hide-from-screenshots")
                Text(settingsString("check.hideFromScreenshots.tip")).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
