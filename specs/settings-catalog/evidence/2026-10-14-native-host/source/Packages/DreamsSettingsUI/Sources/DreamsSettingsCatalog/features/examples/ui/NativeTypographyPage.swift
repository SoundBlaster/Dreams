import SwiftUI

struct NativeTypographyPage: View {
    var body: some View {
        Form {
            Section {
                Text(catalogString("type.sample")).font(.largeTitle)
                Text(catalogString("type.sample")).font(.title)
                Text(catalogString("type.sample")).font(.headline)
                Text(catalogString("type.sample")).font(.body)
                Text(catalogString("type.sample")).font(.caption)
            } header: { Text(catalogString("type.styles")) }
            Section {
                Text(catalogString("type.primary")).foregroundStyle(.primary)
                Text(catalogString("type.secondary")).foregroundStyle(.secondary)
                Text(catalogString("type.longDescription")).foregroundStyle(.secondary)
                LabeledContent { Text(81, format: .number).monospacedDigit() }
                    label: { Text(catalogString("rain.columns")) }
            } header: { Text(catalogString("type.semantics")) }
        }
        .formStyle(.grouped)
    }
}
