import DreamsSettingsUI
import SwiftUI

struct NativeParameterRow: View {
    @Bindable var model: NativeSettingsModel
    let parameter: NativeRainParameter
    @Environment(\.locale) private var locale

    var body: some View {
        SettingsSliderRow(parameter.title, value: $model[parameter: parameter], in: parameter.range,
                          step: parameter.step, readout: parameter.readout(model[parameter: parameter], locale: locale),
                          identifier: parameter.identifier, systemImage: parameter.symbol)
            .help(parameter.help)
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
                        .keyboardShortcut(.defaultAction)
                    Button(settingsString("button.stop")) { model.stop() }
                        .accessibilityIdentifier("dreams.stop")
                }
                Picker(selection: $model.runTime) {
                    ForEach(DreamsPreset.runTimeChoices, id: \.self) { seconds in
                        Text(SettingsPageController.runTimeTitle(seconds)).tag(seconds)
                    }
                } label: {
                    SettingsRowLabel(settingsString("runtime.accessibility"), systemImage: "clock")
                }
                .disabled(model.transparent).accessibilityIdentifier("dreams.run-time")
                .help(settingsString("runtime.tip"))
                Text(model.runTimeHint)
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("dreams.run-time-hint")
            }
            Section(settingsString("hotkey.label")) {
                NativeShortcutRow(model: model)
            }
        }
        .formStyle(.grouped)
    }
}

private struct NativeShortcutRow: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    shortcutValue
                    Spacer(minLength: 12)
                    actions
                }
                VStack(alignment: .leading) {
                    shortcutValue
                    actions
                }
            }
            Text(L("native.escapeHint", model.stopShortcut))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Group {
                if let message = model.shortcutMessage {
                    Text(message).accessibilityIdentifier("dreams.stop-hotkey-message")
                } else if model.isRecordingShortcut {
                    Text(settingsString("hotkey.recording"))
                        .accessibilityIdentifier("dreams.stop-hotkey-recording")
                } else {
                    Text(settingsString("hotkey.tip"))
                }
            }
            .font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var shortcutValue: some View {
        SettingsRowLabel(verbatim: model.stopShortcut, systemImage: "keyboard").monospaced().fixedSize()
            .accessibilityLabel(settingsString("hotkey.label"))
            .accessibilityValue(model.stopShortcut)
    }

    private var actions: some View {
        HStack {
            Button(settingsString(model.isRecordingShortcut ? "button.cancel" : "hotkey.change")) { model.recordShortcut() }
                .accessibilityIdentifier("dreams.stop-hotkey")
                .help(settingsString("hotkey.tip"))
            Button(settingsString("hotkey.reset")) { model.resetShortcut() }
                .accessibilityIdentifier("dreams.stop-hotkey-default")
        }
        .fixedSize()
    }
}

struct NativeAppearanceForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section(settingsString("label.color")) {
                ColorPicker(selection: $model.rainColor, supportsOpacity: false) {
                    SettingsRowLabel(settingsString("rain.color.accessibility"), systemImage: "paintpalette")
                }
                    .accessibilityIdentifier("dreams.rain-color")
                    .help(settingsString("rain.color.tip"))
                NativeParameterRow(model: model, parameter: .glow)
                NativeParameterRow(model: model, parameter: .spread)
                NativeParameterRow(model: model, parameter: .pulse)
            }
            Section(settingsString("section.glyphs")) {
                Toggle(isOn: $model.restoredGlyphs) {
                    SettingsRowLabel(settingsString("check.restored"), systemImage: "character")
                }
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
            Section {
                Toggle(isOn: $model.automaticColumns) {
                    SettingsRowLabel(settingsString("rain.columns.auto"), systemImage: "square.grid.3x3")
                }
                    .accessibilityIdentifier("dreams.rain-columns-auto")
                SettingsSliderRow(settingsString("rain.columns"), value: $model.columns, in: 24...240, step: 1,
                                  readout: Int(model.columns).formatted(), identifier: "dreams.rain-columns", systemImage: "rectangle.split.3x1")
                    .disabled(model.automaticColumns)
                    .help(settingsString("rain.columns.tip"))
                NativeParameterRow(model: model, parameter: .density)
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(settingsString("section.rain")).font(.title2.bold()).foregroundStyle(.primary)
                    Text(settingsString("native.rain.description"))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(settingsString("rain.grid")).padding(.top, 12)
                }
                .textCase(nil)
            }
            Section(settingsString("native.motion")) {
                NativeParameterRow(model: model, parameter: .speed)
                NativeParameterRow(model: model, parameter: .fade)
                Toggle(isOn: $model.decelerationEnabled) {
                    SettingsRowLabel(settingsString("rain.deceleration.enabled"), systemImage: "arrow.down")
                }
                    .accessibilityIdentifier("dreams.rain-deceleration-enabled")
                    .help(settingsString("rain.deceleration.enabled.tip"))
                NativeParameterRow(model: model, parameter: .deceleration).disabled(!model.decelerationEnabled)
            }
            Section {
                NativeParameterRow(model: model, parameter: .search)
            } header: {
                Text(settingsString("rain.search"))
            } footer: {
                Text(settingsString("rain.search.tip"))
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
                Toggle(isOn: $model.transparent) {
                    SettingsRowLabel(settingsString("check.transparent"), systemImage: "square.on.square")
                }
                    .accessibilityIdentifier("dreams.transparent-background")
                Text(settingsString("native.backgroundProfiles")).foregroundStyle(.secondary)
            }
            Section(settingsString("section.between")) {
                NativeParameterRow(model: model, parameter: .idle)
                Text(settingsString("rain.idle.tip")).foregroundStyle(.secondary)
            }
            Section {
                Toggle(isOn: $model.hideFromScreenshots) {
                    SettingsRowLabel(settingsString("check.hideFromScreenshots"), systemImage: "camera")
                }
                    .accessibilityIdentifier("dreams.hide-from-screenshots")
                    .help(settingsString("check.hideFromScreenshots.tip"))
                Text(settingsString("check.hideFromScreenshots.tip")).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
