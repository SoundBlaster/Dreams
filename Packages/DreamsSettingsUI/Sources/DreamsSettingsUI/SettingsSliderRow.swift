import SwiftUI

/// A form composition around the system Slider. The consumer owns state, units and validation.
public struct SettingsSliderRow: View {
    private let title: LocalizedStringResource
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let readout: String
    private let identifier: String
    private let systemImage: String?
    private let helpText: Text?
    @ScaledMetric(relativeTo: .body) private var readoutWidth = 80.0

    public init(_ title: LocalizedStringResource, value: Binding<Double>, in range: ClosedRange<Double>,
                step: Double = 1, readout: String, identifier: String, systemImage: String? = nil,
                help: LocalizedStringResource? = nil) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.readout = readout
        self.identifier = identifier
        self.systemImage = systemImage
        helpText = help.map { Text($0) }
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

    @ViewBuilder private var label: some View {
        if let systemImage {
            SettingsRowLabel(title, systemImage: systemImage)
        } else {
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var slider: some View {
        if let helpText {
            nativeSlider.help(helpText)
        } else {
            nativeSlider
        }
    }

    private var nativeSlider: some View {
        Group {
            if (range.upperBound - range.lowerBound) / step > 20 {
                Slider(value: steppedValue, in: range) { Text(title) }
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: steppedValue.wrappedValue = value + step
                        case .decrement: steppedValue.wrappedValue = value - step
                        @unknown default: break
                        }
                    }
            } else {
                Slider(value: $value, in: range, step: step) { Text(title) }
            }
        }
        .labelsHidden()
        .accessibilityIdentifier(identifier)
        .accessibilityValue(readout)
        .frame(minWidth: 120, maxWidth: .infinity)
    }

    /// Keep value precision independent of the system's densely stepped track drawing.
    private var steppedValue: Binding<Double> {
        Binding(get: { value }, set: { next in
            let steps = ((next - range.lowerBound) / step).rounded()
            value = min(range.upperBound, max(range.lowerBound, range.lowerBound + steps * step))
        })
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
