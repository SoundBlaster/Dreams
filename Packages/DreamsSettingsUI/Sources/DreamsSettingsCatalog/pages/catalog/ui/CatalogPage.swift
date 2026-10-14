import SwiftUI

struct CatalogPage: View {
    @State private var selection: CatalogSection? = .controls
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var disabled = false
    @State private var appearance: CatalogAppearance = .system
    @State private var controlSize: ControlSize = .regular

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            CatalogSidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            CatalogDetail(section: selection)
                .disabled(disabled)
                .controlSize(controlSize)
                .navigationTitle(selection?.title ?? catalogString("catalog.title"))
        }
        .preferredColorScheme(appearance.scheme)
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker(selection: $appearance) {
                        ForEach(CatalogAppearance.allCases) { Text($0.title).tag($0) }
                    } label: { Text(catalogString("catalog.appearance")) }
                    Picker(selection: $controlSize) {
                        Text(catalogString("size.small")).tag(ControlSize.small)
                        Text(catalogString("size.regular")).tag(ControlSize.regular)
                        Text(catalogString("size.large")).tag(ControlSize.large)
                    } label: { Text(catalogString("catalog.controlSize")) }
                    Toggle(isOn: $disabled) { Text(catalogString("catalog.disableExamples")) }
                } label: {
                    Label { Text(catalogString("catalog.options")) } icon: { Image(systemName: "gearshape") }
                }
                .accessibilityIdentifier("catalog.options")
            }
        }
    }
}

struct CatalogSidebar: View {
    @Binding var selection: CatalogSection?

    var body: some View {
        List(CatalogSection.allCases, selection: $selection) { section in
            NavigationLink(value: section) {
                Label { Text(section.title) } icon: { Image(systemName: section.symbol) }
            }
            .accessibilityIdentifier("catalog.section.\(section.rawValue)")
        }
        .navigationTitle(catalogString("catalog.title"))
        .listStyle(.sidebar)
    }
}

struct CatalogDetail: View {
    let section: CatalogSection?

    var body: some View {
        switch section {
        case .controls: NativeControlsPage()
        case .forms: NativeFormPage()
        case .navigation: NativeNavigationPage()
        case .materials: NativeMaterialsPage()
        case .typography: NativeTypographyPage()
        case nil:
            ContentUnavailableView {
                Label { Text(catalogString("catalog.selectSection")) } icon: { Image(systemName: "sidebar.leading") }
            }
        }
    }
}
