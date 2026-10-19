import DreamsSettingsUI
import SwiftUI

struct NativeFormPage: View {
    @State private var automatic = false
    @State private var columns = 80.0
    @State private var density = 0.8
    @State private var speed = 1.0
    @State private var braking = false
    @State private var acceleration = -12.0
    @State private var search = 0.1
    @State private var transparent = false

    var body: some View {
        Form {
            Section {
                Label { Text(catalogString("catalog.fixtureMessage")) } icon: { Image(systemName: "info.circle") }
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle(isOn: $automatic) { SettingsRowLabel(catalogString("rain.automaticColumns"), systemImage: "square.grid.3x3") }
                SettingsSliderRow(catalogString("rain.columns"), value: $columns, in: 24...240,
                                  readout: Int(columns).formatted(), identifier: "catalog.form.columns", systemImage: "rectangle.split.3x1")
                    .disabled(automatic)
                SettingsSliderRow(catalogString("rain.density"), value: $density, in: 0...1, step: 0.01,
                                  readout: density.formatted(.percent.precision(.fractionLength(0))), identifier: "catalog.form.density", systemImage: "drop")
            } header: { Text(catalogString("rain.layout")) }
            Section {
                SettingsSliderRow(catalogString("rain.speed"), value: $speed, in: 0.1...3, step: 0.01,
                                  readout: speed.formatted(.number.precision(.fractionLength(2))) + "×", identifier: "catalog.form.speed", systemImage: "bolt")
                Toggle(isOn: $braking) { SettingsRowLabel(catalogString("rain.braking"), systemImage: "arrow.down") }
                SettingsSliderRow(catalogString("rain.acceleration"), value: $acceleration, in: -120...0,
                                  readout: acceleration.formatted() + " rows/s²", identifier: "catalog.form.acceleration", systemImage: "arrow.down")
                    .disabled(!braking)
                SettingsSliderRow(catalogString("rain.search"), value: $search, in: 0...1, step: 0.01,
                                  readout: search.formatted(.percent.precision(.fractionLength(0))), identifier: "catalog.form.search", systemImage: "magnifyingglass")
            } header: { Text(catalogString("rain.motion")) }
            Section {
                Toggle(isOn: $transparent) { SettingsRowLabel(catalogString("rain.transparent"), systemImage: "square.on.square") }
            } header: { Text(catalogString("rain.background")) }
            Section {
                Button {
                    automatic = false
                    columns = 80
                    density = 0.8
                    speed = 1
                    braking = false
                    acceleration = -12
                    search = 0.1
                    transparent = false
                } label: {
                    Label { Text(catalogString("action.resetFixture")) } icon: { Image(systemName: "arrow.counterclockwise") }
                }
            }
        }
        .formStyle(.grouped)
    }
}
