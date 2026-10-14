import DreamsSettingsUI
import SwiftUI

struct NativeMaterialsPage: View {
    var body: some View {
        Form {
            Section {
                Text(catalogString("materials.system")).foregroundStyle(.secondary)
            }
            Section {
                MaterialSpecimen()
            } header: { Text(catalogString("materials.standard")) }
            Section {
                GlassSpecimen()
            } header: { Text(catalogString("materials.glass")) }
            Section {
                SettingsPreviewRegion {
                    ContentUnavailableView {
                        Label { Text(catalogString("materials.preview")) } icon: { Image(systemName: "rectangle.split.2x1") }
                    } description: { Text(catalogString("materials.previewDescription")) }
                    .frame(minHeight: 170)
                }
                Text(catalogString("materials.previewCaption")).foregroundStyle(.secondary)
            } header: { Text(catalogString("materials.openRegion")) }
        }
        .formStyle(.grouped)
    }
}

struct MaterialSpecimen: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        ZStack {
            LinearGradient(colors: [.green.opacity(0.5), .blue.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
            Text(catalogString("materials.standardCaption"))
                .padding()
                .background(reduceTransparency ? AnyShapeStyle(.background) : AnyShapeStyle(.regularMaterial),
                            in: RoundedRectangle(cornerRadius: 12))
                .padding()
        }
        .frame(minHeight: 120)
        .clipShape(.rect(cornerRadius: 12))
    }
}

struct GlassSpecimen: View {
    @State private var activated = false
    var body: some View {
        if #available(macOS 26.0, *) {
            VStack(alignment: .leading) {
                Text(catalogString("materials.glassCaption")).foregroundStyle(.secondary)
                HStack {
                    Button { activated.toggle() } label: { Text(catalogString("action.secondary")) }.buttonStyle(.glass)
                    Button { activated.toggle() } label: { Text(catalogString("action.primary")) }.buttonStyle(.glassProminent)
                }
                Text(activated ? catalogString("materials.actionOn") : catalogString("materials.actionOff"))
            }
        } else {
            Text(catalogString("materials.unavailable"))
        }
    }
}
