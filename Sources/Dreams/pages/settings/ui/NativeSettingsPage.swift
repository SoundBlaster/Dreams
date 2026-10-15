import DreamsSettingsUI
import SwiftUI

struct NativeSettingsPage: View {
    let model: NativeSettingsModel
    @State private var selection: NativeSettingsSection?
    @State private var visibility: NavigationSplitViewVisibility = .all

    init(model: NativeSettingsModel, initialSection: NativeSettingsSection = .general) {
        self.model = model
        _selection = State(initialValue: initialSection)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(NativeSettingsSection.allCases, selection: $selection) { section in
                NavigationLink(value: section) { Label(section.title, systemImage: section.symbol) }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dreams")
            .navigationSplitViewColumnWidth(min: 170, ideal: 220, max: 300)
        } detail: {
            ZStack {
                NativeRainBackdrop(session: model.preview)
                GeometryReader { geometry in
                    if geometry.size.width >= 700 {
                        HStack(spacing: 16) {
                            settingsPanel
                            NativePreviewPane(session: model.preview).frame(width: 280)
                        }
                        .padding(16)
                    } else {
                        VStack(spacing: 16) {
                            NativePreviewPane(session: model.preview).frame(height: 180)
                            settingsPanel
                        }
                        .padding(16)
                    }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }

    private var settingsPanel: some View {
        SettingsMaterialPanel {
            NativeSettingsDetail(section: selection, model: model)
                .scrollContentBackground(.hidden)
        }
    }
}

private struct NativeSettingsDetail: View {
    let section: NativeSettingsSection?
    @Bindable var model: NativeSettingsModel

    var body: some View {
        Group {
            switch section {
            case .general: NativeGeneralForm(model: model)
            case .appearance: NativeAppearanceForm(model: model)
            case .rain: NativeRainForm(model: model)
            case .background: NativeBackgroundForm(model: model)
            case .words: NativeWordsForm(model: model)
            case .displays: NativeDisplaysForm(model: model)
            case .advanced: NativeAdvancedForm(model: model)
            case .none: ContentUnavailableView(settingsString("native.selectSection"), systemImage: "sidebar.leading")
            }
        }
        .navigationTitle(section?.title ?? settingsString("menu.openControls"))
        .alert(settingsString("native.error"), isPresented: $model.hasError) {
            Button(settingsString("button.ok"), role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}
