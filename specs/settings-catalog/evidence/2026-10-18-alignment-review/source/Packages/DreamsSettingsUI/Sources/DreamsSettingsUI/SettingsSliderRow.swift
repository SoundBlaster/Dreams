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
        ViewThatFits(in: .horizontal) {
            HStack {
                label.frame(minWidth: 80, maxWidth: .infinity, alignment: .leading)
                slider
                readoutColumn
            }
            VStack(alignment: .leading) {
                label
                ViewThatFits(in: .horizontal) {
                    HStack {
                        slider
                        readoutColumn
                    }
                    VStack(alignment: .trailing) {
                        readoutText.fixedSize(horizontal: false, vertical: true)
                        slider
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var label: some View {
        Text(title).fixedSize(horizontal: false, vertical: true)
    }

    private var slider: some View {
        Slider(value: $value, in: range, step: step) { Text(title) }
            .labelsHidden()
            .accessibilityIdentifier(identifier)
            .accessibilityValue(readout)
            .frame(minWidth: 120, maxWidth: .infinity)
    }

    private var readoutColumn: some View {
        readoutText.fixedSize().frame(minWidth: readoutWidth, alignment: .trailing)
    }

    private var readoutText: some View {
        Text(verbatim: readout)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}
