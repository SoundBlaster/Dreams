import AppKit
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
                    .listItemTint(model.rainColor)
            }
            .listStyle(.sidebar)
            .toolbar(removing: .sidebarToggle)
            .safeAreaInset(edge: .top) {
                VStack(spacing: 12) {
                    HStack {
                        Color.clear.frame(height: 28).gesture(WindowDragGesture())
                        sidebarButton
                    }
                    NativeSidebarBrand()
                }
                .padding(.horizontal, 12)
                .padding(.top, 28)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 220, max: 300)
        } detail: {
            ZStack {
                NativeRainBackdrop(session: model.preview)
                GeometryReader { geometry in
                    if geometry.size.width >= 700 {
                        HStack(spacing: 16) {
                            settingsPanel
                                .frame(width: min(480, geometry.size.width - 48 - 240))
                            NativePreviewPane(session: model.preview, outlined: selection == .rain)
                                .frame(minWidth: 240, maxWidth: .infinity)
                        }
                        .padding(16)
                    } else {
                        VStack(spacing: 16) {
                            NativePreviewPane(session: model.preview, outlined: selection == .rain).frame(height: 180)
                            settingsPanel
                        }
                        .padding(16)
                    }
                }
                .padding(.top, visibility == .detailOnly ? 32 : 0)
            }
            .ignoresSafeArea(.container, edges: .top)
            .overlay(alignment: .topLeading) {
                if visibility == .detailOnly {
                    sidebarButton.padding(.leading, 100).padding(.top, 8)
                }
            }
        }
        .toolbar(removing: .sidebarToggle)
        .toolbarVisibility(.hidden, for: .windowToolbar)
        .tint(model.rainColor)
        .frame(minWidth: 560, minHeight: 420)
        .onChange(of: selection) { _, _ in model.cancelShortcutRecording() }
    }

    private var settingsPanel: some View {
        SettingsMaterialPanel {
            VStack(alignment: .leading, spacing: 0) {
                if let selection, selection != .rain {
                    Text(selection.title).font(.title2.bold())
                        .padding(.horizontal, 24).padding(.top, 20)
                }
                NativeSettingsDetail(section: selection, model: model)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var sidebarButton: some View {
        Button {
            visibility = visibility == .detailOnly ? .all : .detailOnly
        } label: {
            Label(settingsString("native.toggleSidebar"), systemImage: "sidebar.leading")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .keyboardShortcut("s", modifiers: [.control, .command])
        .help(settingsString("native.toggleSidebar"))
        .accessibilityIdentifier("dreams.native.toggle-sidebar")
    }
}

private struct NativeSidebarBrand: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().scaledToFit().frame(width: 64, height: 64)
                .accessibilityHidden(true)
            Text(verbatim: "Dreams").font(.headline)
            Text(settingsString("native.brand.subtitle"))
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dreams.native.sidebar-brand")
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
        .alert(settingsString("native.error"), isPresented: $model.hasError) {
            Button(settingsString("button.ok"), role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}
