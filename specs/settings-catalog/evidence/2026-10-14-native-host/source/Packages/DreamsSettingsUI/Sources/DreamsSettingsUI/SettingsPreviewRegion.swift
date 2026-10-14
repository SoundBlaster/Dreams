import SwiftUI

/// An uncovered content region. A host may later supply its renderer without changing controls.
public struct SettingsPreviewRegion<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 12))
    }
}
