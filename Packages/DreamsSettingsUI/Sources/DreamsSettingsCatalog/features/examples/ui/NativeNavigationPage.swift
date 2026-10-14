import SwiftUI

struct NativeNavigationPage: View {
    @State private var inspector = false
    @State private var expanded = false

    var body: some View {
        Form {
            Section {
                Text(catalogString("navigation.systemSidebar"))
                Text(catalogString("navigation.windowSize")).foregroundStyle(.secondary)
            } header: { Text(catalogString("navigation.split")) }
            Section {
                DisclosureGroup(isExpanded: $expanded) {
                    Text(catalogString("navigation.disclosureContent"))
                } label: { Text(catalogString("navigation.disclosure")) }
                Button { inspector.toggle() } label: { Text(catalogString("navigation.inspector")) }
            } header: { Text(catalogString("navigation.secondary")) }
            Section {
                ContentUnavailableView {
                    Label { Text(catalogString("navigation.empty")) } icon: { Image(systemName: "sidebar.leading") }
                } description: { Text(catalogString("navigation.emptyDescription")) }
            } header: { Text(catalogString("navigation.emptyState")) }
        }
        .formStyle(.grouped)
        .inspector(isPresented: $inspector) {
            Form {
                Section {
                    Text(catalogString("navigation.inspectorContent"))
                    Button { inspector = false } label: { Text(catalogString("action.close")) }
                } header: { Text(catalogString("navigation.inspector")) }
            }
            .formStyle(.grouped)
            .inspectorColumnWidth(min: 180, ideal: 240, max: 320)
        }
    }
}
