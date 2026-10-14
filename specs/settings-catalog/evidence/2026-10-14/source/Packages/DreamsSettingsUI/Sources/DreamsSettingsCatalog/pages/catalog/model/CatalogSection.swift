import SwiftUI

enum CatalogSection: String, CaseIterable, Identifiable {
    case controls, forms, navigation, materials, typography

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .controls: catalogString("catalog.controls")
        case .forms: catalogString("catalog.forms")
        case .navigation: catalogString("catalog.navigation")
        case .materials: catalogString("catalog.materials")
        case .typography: catalogString("catalog.typography")
        }
    }

    var symbol: String {
        switch self {
        case .controls: "slider.horizontal.3"
        case .forms: "list.bullet.rectangle"
        case .navigation: "rectangle.split.2x1"
        case .materials: "square.stack.3d.up"
        case .typography: "textformat"
        }
    }
}

enum CatalogAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .system: catalogString("appearance.system")
        case .light: catalogString("appearance.light")
        case .dark: catalogString("appearance.dark")
        }
    }
    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
