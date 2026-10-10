// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Dreams",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "Dreams", targets: ["Dreams"])],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", exact: "0.12.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0")
    ],
    targets: [
        .target(name: "VirtualDisplayBridge", publicHeadersPath: "include",
                cSettings: [.unsafeFlags(["-fobjc-arc"])],
                linkerSettings: [.linkedFramework("CoreGraphics")]),
        .executableTarget(name: "Dreams", dependencies: [
            "VirtualDisplayBridge", .product(name: "MCP", package: "swift-sdk"),
            .product(name: "Logging", package: "swift-log")
        ], resources: [.copy("Rain.metal"), .copy("Matrix-Code.ttf"), .copy("DreamsMatrix.ttf"), .process("Localization")])
    ]
)
