import DreamsSettingsUI
import SwiftUI

struct NativeControlsPage: View {
    @State private var checkbox = true
    @State private var switchValue = false
    @State private var choice = 0
    @State private var columns = 80.0
    @State private var density = 0.6
    @State private var name = "Classic"
    @State private var notes = ""
    @State private var color = Color.green
    @State private var showAlert = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Button { showAlert = true } label: { Text(catalogString("action.primary")) }
                        .buttonStyle(.borderedProminent)
                    Button { showAlert = true } label: { Text(catalogString("action.secondary")) }
                        .buttonStyle(.bordered)
                    Button(role: .destructive) { showAlert = true } label: { Text(catalogString("action.remove")) }
                }
            } header: { Text(catalogString("controls.buttons")) }
            Section {
                Toggle(isOn: $checkbox) { Text(catalogString("controls.checkbox")) }.toggleStyle(.checkbox)
                Toggle(isOn: $switchValue) { Text(catalogString("controls.switch")) }.toggleStyle(.switch)
                Toggle(isOn: .constant(true)) { Text(catalogString("controls.unavailable")) }.disabled(true)
            } header: { Text(catalogString("controls.toggles")) }
            Section {
                CatalogChoicePicker(selection: $choice)
                CatalogChoicePicker(selection: $choice).pickerStyle(.segmented)
                ColorPicker(selection: $color, supportsOpacity: false) { Text(catalogString("controls.color")) }
            } header: { Text(catalogString("controls.choice")) }
            Section {
                SettingsSliderRow(catalogString("rain.columns"), value: $columns, in: 24...240,
                                  readout: Int(columns).formatted(), identifier: "catalog.columns")
                SettingsSliderRow(catalogString("rain.density"), value: $density, in: 0...1, step: 0.01,
                                  readout: density.formatted(.percent.precision(.fractionLength(0))), identifier: "catalog.density")
                Stepper(value: $columns, in: 24...240) {
                    Text(catalogString("controls.exactColumns"))
                    Text(Int(columns), format: .number).monospacedDigit()
                }
            } header: { Text(catalogString("controls.values")) }
            Section {
                TextField(text: $name) { Text(catalogString("controls.name")) }
                LabeledContent { TextEditor(text: $notes).frame(minHeight: 70) }
                    label: { Text(catalogString("controls.notes")) }
            } header: { Text(catalogString("controls.text")) }
            Section {
                ProgressView(value: 0.64) { Text(catalogString("controls.progress")) }
                Label { Text(catalogString("controls.ready")) } icon: { Image(systemName: "checkmark.circle") }
                    .foregroundStyle(.secondary)
                ProgressView { Text(catalogString("controls.busy")) }
            } header: { Text(catalogString("controls.feedback")) }
        }
        .formStyle(.grouped)
        .alert(catalogString("catalog.fixtureTitle"), isPresented: $showAlert) {
            Button(role: .cancel) {} label: { Text(catalogString("action.close")) }
        } message: { Text(catalogString("catalog.fixtureMessage")) }
    }
}

struct CatalogChoicePicker: View {
    @Binding var selection: Int
    var body: some View {
        Picker(selection: $selection) {
            Text(catalogString("choice.automatic")).tag(0)
            Text(catalogString("choice.selected")).tag(1)
            Text(catalogString("choice.all")).tag(2)
        } label: { Text(catalogString("choice.display")) }
    }
}
