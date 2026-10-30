// swift-tools-version: 6.2
import PackageDescription
import Foundation

let metalPilot = ProcessInfo.processInfo.environment["DREAMS_METAL_PILOT"] == "1"
let pilotScreenerPath = metalPilot ? ProcessInfo.processInfo.environment["DREAMS_SCREENER_PATH"] : nil
let screenerDependency: Package.Dependency = pilotScreenerPath.map { .package(path: $0) }
    ?? .package(url: "https://github.com/SoundBlaster/Screener.git", exact: "0.1.0")

let package = Package(
    name: "Dreams",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "Dreams", targets: ["Dreams"])],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", exact: "0.12.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        screenerDependency
    ],
    targets: [
        .target(name: "VirtualDisplayBridge", publicHeadersPath: "include",
                cSettings: [.unsafeFlags(["-fobjc-arc"])],
                linkerSettings: [.linkedFramework("CoreGraphics")]),
        .executableTarget(name: "Dreams", dependencies: [
            "VirtualDisplayBridge", .product(name: "MCP", package: "swift-sdk"),
            .product(name: "Logging", package: "swift-log")
        ] + (metalPilot ? [.product(name: "ScreenerKit", package: "Screener"),
            .product(name: "ScreenerScreenCaptureKit", package: "Screener")] : []), resources: [.copy("Rain.metal"), .copy("Matrix-Code.ttf"), .copy("DreamsMatrix.ttf"), .process("shared/assets/Localization")],
            swiftSettings: metalPilot ? [.define("DREAMS_METAL_PILOT")] : []),
        .testTarget(name: "DreamsTests", dependencies: ["Dreams", .product(name: "ScreenerKit", package: "Screener")])
    ]
)
