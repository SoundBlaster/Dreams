import SwiftUI

/// A native row label with a shared decorative symbol slot.
public struct SettingsRowLabel: View {
    private let title: Text
    private let systemImage: String

    public init(_ title: LocalizedStringResource, systemImage: String) {
        self.title = Text(title)
        self.systemImage = systemImage
    }

    public init(verbatim title: String, systemImage: String) {
        self.title = Text(verbatim: title)
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            title.fixedSize(horizontal: false, vertical: true)
        }
    }
}
