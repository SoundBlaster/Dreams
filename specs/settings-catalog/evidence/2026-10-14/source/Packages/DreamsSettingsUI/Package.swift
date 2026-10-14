// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DreamsSettingsUI",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DreamsSettingsUI", targets: ["DreamsSettingsUI"]),
        .executable(name: "DreamsSettingsCatalog", targets: ["DreamsSettingsCatalog"])
    ],
    targets: [
        .target(name: "DreamsSettingsUI"),
        .executableTarget(name: "DreamsSettingsCatalog", dependencies: ["DreamsSettingsUI"],
                          resources: [.process("shared/assets/Localization")])
    ]
)
