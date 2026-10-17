import SwiftUI

/// A form composition around the system Slider. The consumer owns state, units and validation.
public struct SettingsSliderRow: View {
    private let title: LocalizedStringResource
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let readout: String
    private let identifier: String
    @ScaledMetric(relativeTo: .body) private var readoutWidth = 80.0

    public init(_ title: LocalizedStringResource, value: Binding<Double>, in range: ClosedRange<Double>,
                step: Double = 1, readout: String, identifier: String) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.readout = readout
        self.identifier = identifier
    }

    public var body: some View {
        // Equal flexible columns keep labels and slider tracks aligned across Form
        // sections. Reserve a shared, text-scaled column so changing values do not
        // resize the tracks. Long localized titles wrap within their column.
        HStack {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Slider(value: $value, in: range, step: step) { Text(title) }
                .labelsHidden()
                .accessibilityIdentifier(identifier)
                .accessibilityValue(readout)
                .frame(minWidth: 0, maxWidth: .infinity)
            Text(verbatim: readout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
                .frame(width: readoutWidth, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}
