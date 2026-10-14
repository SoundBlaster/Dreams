import AppKit
import Observation
import SwiftUI

/// A presentation adapter. The existing rain controller remains the sole saved-settings owner.
@MainActor
@Observable
final class NativeSettingsModel {
    @ObservationIgnored let controller: DreamsController
    @ObservationIgnored private weak var owner: SettingsPageController?
    private var revision = 0
    var activity = ""
    var errorMessage: String?

    init(owner: SettingsPageController) {
        self.owner = owner
        controller = owner.controller
    }

    func refresh() { revision &+= 1 }

    private func read<Value>(_ keyPath: KeyPath<DreamsController, Value>) -> Value {
        _ = revision
        return controller[keyPath: keyPath]
    }

    subscript(parameter parameter: NativeRainParameter) -> Double {
        get { read(parameter.keyPath) }
        set {
            guard newValue.isFinite else { return }
            let bounded = min(parameter.range.upperBound, max(parameter.range.lowerBound, newValue))
            controller[keyPath: parameter.keyPath] = parameter == .fade ? bounded.rounded() : bounded
        }
    }

    var automaticColumns: Bool {
        get { read(\.rainColumnCount) == 0 }
        set { controller.rainColumnCount = newValue ? 0 : min(240, max(24, controller.automaticColumnCount)) }
    }
    var columns: Double {
        get { Double(automaticColumns ? read(\.automaticColumnCount) : read(\.rainColumnCount)) }
        set {
            guard newValue.isFinite else { return }
            controller.rainColumnCount = Int(min(240, max(24, newValue)).rounded())
        }
    }
    var decelerationEnabled: Bool {
        get { read(\.rainDecelerationEnabled) }
        set { controller.rainDecelerationEnabled = newValue }
    }
    var transparent: Bool {
        get { read(\.transparentBackground) }
        set { perform { try controller.setTransparentBackground(newValue) } }
    }
    var restoredGlyphs: Bool {
        get { read(\.restoredGlyphs) }
        set { perform { try controller.setRestoredGlyphs(newValue) } }
    }
    var hideFromScreenshots: Bool {
        get { read(\.hideFromScreenshots) }
        set { controller.setHideFromScreenshots(newValue) }
    }
    var runTime: Double {
        get { read(\.runTimeSeconds) }
        set {
            guard DreamsPreset.runTimeChoices.contains(newValue) else { return }
            controller.runTimeSeconds = newValue
        }
    }
    var rainColor: Color {
        get { Color(nsColor: read(\.rainColor)) }
        set { controller.rainColor = NSColor(newValue) }
    }
    var keywordColor: Color {
        get { Color(nsColor: read(\.keywordColor)) }
        set { controller.keywordColor = NSColor(newValue) }
    }
    var stopShortcut: String { read(\.stopHotkey).display }
    var displays: [RainDisplay] { read(\.displays) }
    var displayMode: RainDisplaySelection.Mode {
        get { read(\.displaySelection).mode }
        set {
            var selection = controller.displaySelection
            if newValue == .selected && selection.selectedIDs.isEmpty {
                selection.selectedIDs = Set(selection.targets(in: controller.displays).map(\.id))
            }
            selection.mode = newValue
            perform { try controller.setDisplaySelection(selection) }
        }
    }
    subscript(display id: String) -> Bool {
        get {
            guard displays.contains(where: { $0.id == id && !$0.excluded }) else { return false }
            let selection = read(\.displaySelection)
            return selection.mode == .selected ? selection.selectedIDs.contains(id)
                : selection.targets(in: displays).contains { $0.id == id }
        }
        set {
            var selection = controller.displaySelection
            guard selection.mode == .selected, displays.contains(where: { $0.id == id && !$0.excluded }) else { return }
            if newValue { selection.selectedIDs.insert(id) }
            else { selection.selectedIDs.remove(id) }
            perform { try controller.setDisplaySelection(selection) }
        }
    }
    var displayHint: String {
        let selection = read(\.displaySelection)
        var text = L("display.hint." + selection.mode.rawValue)
        if selection.mode == .selected && Set(selection.targets(in: displays).map(\.id)).isDisjoint(with: selection.selectedIDs) {
            text += " " + L("display.fallback")
        }
        let missing = selection.selectedIDs.subtracting(displays.map(\.id)).count
        if missing > 0 { text += " " + L("display.disconnected", missing) }
        if let error = read(\.displayError) { text += "\n" + L("status.displayError", error) }
        return text
    }
    var hasError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func hookState(_ source: String) -> HooksInstaller.State {
        _ = revision
        return HooksInstaller.state(source: source)
    }
    func toggleHooks(_ source: String) { owner?.toggleHooks(source: source) }
    func start() { perform { try controller.startWithRunTime() }; owner?.refreshActivityLabel() }
    func stop() { controller.stop(); owner?.refreshActivityLabel() }
    func showLegacy() { owner?.showLegacyControls() }
    func showFixtures() { perform { try controller.showEventFixtures() } }
    func reset() {
        perform {
            try controller.resetToDefaults()
            owner?.applyStopHotkey(controller.stopHotkey)
            owner?.syncControls()
        }
    }
    private func perform(_ operation: () throws -> Void) {
        do { try operation() }
        catch { errorMessage = error.localizedDescription }
        refresh()
    }
}
