import SwiftUI

@main
struct DreamsSettingsCatalogApp: App {
    var body: some Scene {
        WindowGroup {
            CatalogPage()
                .frame(minWidth: 560, minHeight: 420)
        }
        .defaultSize(width: 1060, height: 760)
        .windowResizability(.contentMinSize)
    }
}
