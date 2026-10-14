import SwiftUI

struct NativeWordsForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section(settingsString("section.words")) {
                ColorPicker(settingsString("words.color.accessibility"), selection: $model.keywordColor, supportsOpacity: false)
                    .accessibilityIdentifier("dreams.keyword-color")
                NativeParameterRow(model: model, parameter: .keywordBrightness)
            }
            Section(settingsString("section.agents")) {
                ForEach(HooksInstaller.targets.map(\.0), id: \.self) { source in
                    NativeHookRow(model: model, source: source)
                }
                Text(settingsString("hooks.note")).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct NativeHookRow: View {
    let model: NativeSettingsModel
    let source: String

    var body: some View {
        let state = model.hookState(source)
        LabeledContent(L("hooks." + source)) {
            HStack {
                Text(L("hooks.state." + state.rawValue)).foregroundStyle(.secondary)
                Button(actionTitle(state)) { model.toggleHooks(source) }
                    .disabled(state == .plugin).accessibilityIdentifier("dreams.hooks-" + source)
            }
        }
    }
    private func actionTitle(_ state: HooksInstaller.State) -> String {
        L(state == .connected ? "button.disconnect" : state == .outdated ? "button.update"
          : state == .duplicate ? "button.removeDuplicate" : state == .plugin ? "button.plugin" : "button.connect")
    }
}

struct NativeDisplaysForm: View {
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Form {
            Section(settingsString("section.displays")) {
                Picker(settingsString("section.displays"), selection: $model.displayMode) {
                    ForEach(RainDisplaySelection.Mode.allCases, id: \.self) { mode in
                        Text(L("display.mode." + mode.rawValue)).tag(mode)
                    }
                }
                .accessibilityIdentifier("dreams.display-mode")
                ForEach(model.displays, id: \.id) { display in
                    Toggle(display.name, isOn: $model[display: display.id])
                        .disabled(model.displayMode != .selected || display.excluded)
                        .accessibilityIdentifier("dreams.display-" + display.id)
                }
                Text(model.displayHint).foregroundStyle(.secondary).accessibilityIdentifier("dreams.display-hint")
            }
        }
        .formStyle(.grouped)
    }
}

struct NativeAdvancedForm: View {
    let model: NativeSettingsModel
    @State private var confirmingReset = false

    var body: some View {
        Form {
            Section {
                Button(settingsString("native.legacy")) { model.showLegacy() }
                    .accessibilityIdentifier("dreams.native.open-legacy")
                Text(settingsString("native.legacyHint")).foregroundStyle(.secondary)
            }
            Section(settingsString("debug.menu")) {
                Button(settingsString("debug.fixtures")) { model.showFixtures() }
                    .accessibilityIdentifier("dreams.event-fixtures")
                Text(settingsString("debug.fixtures.tip")).foregroundStyle(.secondary)
            }
            Section {
                Button(settingsString("button.reset"), role: .destructive) { confirmingReset = true }
                    .accessibilityIdentifier("dreams.reset-defaults")
                Text(settingsString("button.reset.tip")).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(settingsString("reset.confirm.title"), isPresented: $confirmingReset) {
            Button(settingsString("reset.confirm.action"), role: .destructive) { model.reset() }
            Button(settingsString("button.cancel"), role: .cancel) {}
        } message: { Text(settingsString("reset.confirm.text")) }
    }
}
