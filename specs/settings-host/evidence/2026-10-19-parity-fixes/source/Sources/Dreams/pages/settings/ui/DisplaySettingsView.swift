import AppKit

/// Display controls own only presentation; the rain controller owns the saved choice and windows.
@MainActor
final class DisplaySettingsView: NSStackView {
    let modePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    let displayList = NSStackView()
    let hint = NSTextField(wrappingLabelWithString: "")
    private let controller: DreamsController
    private(set) var displayButtons: [String: NSButton] = [:]

    init(controller: DreamsController) {
        self.controller = controller
        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = 8
        widthAnchor.constraint(equalToConstant: 420).isActive = true
        for mode in RainDisplaySelection.Mode.allCases {
            modePopup.addItem(withTitle: L("display.mode." + mode.rawValue))
            modePopup.lastItem?.representedObject = mode.rawValue
        }
        modePopup.target = self
        modePopup.action = #selector(changeMode(_:))
        modePopup.setAccessibilityIdentifier("dreams.display-mode")
        modePopup.setAccessibilityLabel(L("section.displays"))
        displayList.orientation = .vertical
        displayList.alignment = .leading
        displayList.spacing = 6
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.preferredMaxLayoutWidth = 420
        hint.setAccessibilityIdentifier("dreams.display-hint")
        addArrangedSubview(modePopup)
        addArrangedSubview(displayList)
        addArrangedSubview(hint)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
            name: DreamsController.displaysDidChange, object: controller)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc func refresh() {
        let selection = controller.displaySelection
        modePopup.selectItem(at: RainDisplaySelection.Mode.allCases.firstIndex(of: selection.mode) ?? 0)
        for view in displayList.arrangedSubviews {
            displayList.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        displayButtons.removeAll()
        let displays = controller.displays
        let targets = Set(selection.targets(in: displays).map(\.id))
        for display in displays {
            let title = display.settingsTitle
            let button = NSButton(checkboxWithTitle: title, target: self, action: #selector(toggleDisplay(_:)))
            button.identifier = NSUserInterfaceItemIdentifier(display.id)
            button.setAccessibilityIdentifier("dreams.display-" + display.id)
            button.toolTip = title
            button.lineBreakMode = .byTruncatingTail
            button.widthAnchor.constraint(lessThanOrEqualToConstant: 420).isActive = true
            let checked = selection.mode == .selected ? selection.selectedIDs.contains(display.id) : targets.contains(display.id)
            button.state = checked && !display.excluded ? .on : .off
            button.isEnabled = selection.mode == .selected && !display.excluded
            displayButtons[display.id] = button
            displayList.addArrangedSubview(button)
        }
        let missing = selection.selectedIDs.subtracting(displays.map(\.id)).count
        var text = L("display.hint." + selection.mode.rawValue)
        if selection.mode == .selected && targets.isDisjoint(with: selection.selectedIDs) {
            text += " " + L("display.fallback")
        }
        if missing > 0 { text += " " + L("display.disconnected", missing) }
        if let error = controller.displayError { text += "\n" + L("status.displayError", error) }
        hint.stringValue = text
    }

    @objc func changeMode(_ sender: NSPopUpButton) {
        guard let raw = sender.selectedItem?.representedObject as? String,
              let mode = RainDisplaySelection.Mode(rawValue: raw) else { return }
        var selection = controller.displaySelection
        if mode == .selected && selection.selectedIDs.isEmpty {
            selection.selectedIDs = Set(selection.targets(in: controller.displays).map(\.id))
        }
        selection.mode = mode
        apply(selection)
    }

    @objc func toggleDisplay(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        var selection = controller.displaySelection
        guard selection.mode == .selected else { return }
        if sender.state == .on { selection.selectedIDs.insert(id) }
        else { selection.selectedIDs.remove(id) }
        apply(selection)
    }

    private func apply(_ selection: RainDisplaySelection) {
        do { try controller.setDisplaySelection(selection) }
        catch { refresh(); NSAlert(error: error).runModal() }
    }
}

extension RainDisplay {
    /// Both settings presentations identify display roles with the same localized suffixes.
    var settingsTitle: String {
        var parts = [name]
        if builtIn { parts.append(L("display.builtIn")) }
        if isMain { parts.append(L("display.main")) }
        if excluded { parts.append(L("display.agentWorkspace")) }
        return parts.joined(separator: " · ")
    }
}
