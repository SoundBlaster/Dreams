import SwiftUI

/// A system material surface for content over a live backdrop.
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
            .background(reduceTransparency || contrast == .increased
                ? AnyShapeStyle(.background) : AnyShapeStyle(.regularMaterial),
                in: RoundedRectangle(cornerRadius: 16))
            .clipShape(.rect(cornerRadius: 16))
    }
}
