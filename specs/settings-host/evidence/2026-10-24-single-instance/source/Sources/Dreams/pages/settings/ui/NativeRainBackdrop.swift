import SwiftUI

/// One continuous renderer behind the form and the open preview region.
struct NativeRainBackdrop: View {
    let session: RainPreviewSession
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        if #available(macOS 26.0, *) {
            surface.backgroundExtensionEffect(isEnabled: !reduceTransparency && contrast != .increased)
        } else {
            surface
        }
    }

    private var surface: some View {
        RainPreviewSurface(session: session)
            .id(session.surfaceGeneration)
            .background(.black)
            .allowsHitTesting(false)
    }
}
