import SwiftUI

/// A form composition around the system Slider. The consumer owns state, units and validation.
public struct SettingsSliderRow: View {
    private let title: LocalizedStringResource
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let readout: String
    private let identifier: String

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
        LabeledContent {
            HStack {
                Slider(value: $value, in: range, step: step) { Text(title) }
                    .labelsHidden()
                    .accessibilityIdentifier(identifier)
                    .accessibilityValue(readout)
                Text(verbatim: readout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .accessibilityHidden(true)
            }
        } label: {
            Text(title)
        }
    }
}
