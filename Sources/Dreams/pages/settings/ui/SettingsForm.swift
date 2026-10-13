import AppKit

extension SettingsPageController {
    static func name(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
    }

    static func note(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = 420
        return label
    }

    static func section(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    static func separator() -> NSBox {
        let line = NSBox()
        line.boxType = .separator
        line.widthAnchor.constraint(equalToConstant: 420).isActive = true
        return line
    }

    /// One settings row: name · slider · value. The hint lives in tooltips, not on screen.
    func sliderRow(_ title: String, value: Double, min: Double, max: Double, action: Selector,
                   valueLabel: NSTextField, ticks: Int = 0, identifier: String, tip: String) -> [NSView] {
        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: self, action: action)
        slider.isContinuous = true
        if ticks > 0 {
            slider.numberOfTickMarks = ticks
            slider.allowsTickMarkValuesOnly = true
        }
        slider.setAccessibilityLabel(title)
        slider.setAccessibilityIdentifier(identifier)
        controlsByID[identifier] = slider
        slider.toolTip = tip
        let label = Self.name(title)
        label.toolTip = tip
        valueLabel.alignment = .right
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return [label, slider, valueLabel]
    }

    /// Fixed column widths keep the rows of every section aligned with each other.
    func settingsGrid(_ rows: [[NSView]]) -> NSGridView {
        let grid = NSGridView(views: rows)
        grid.rowSpacing = 6
        grid.columnSpacing = 12
        grid.column(at: 0).width = 120
        grid.column(at: 1).width = 220
        grid.column(at: 2).width = 64
        grid.column(at: 2).xPlacement = .trailing
        for index in 0..<grid.numberOfRows { grid.row(at: index).yPlacement = .center }
        return grid
    }

}
