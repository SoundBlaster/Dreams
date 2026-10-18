import SwiftUI

/// A system glass surface for controls over a live backdrop.
/// Accessibility preferences replace translucency with an opaque system background.
public struct SettingsMaterialPanel<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background {
                if reduceTransparency || contrast == .increased {
                    RoundedRectangle(cornerRadius: 16).fill(.background)
                } else if #available(macOS 26.0, *) {
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
    }
}
