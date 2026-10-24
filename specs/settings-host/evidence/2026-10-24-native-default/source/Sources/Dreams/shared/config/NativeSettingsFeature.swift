/// Native settings are the default; the explicit legacy override remains available.
enum NativeSettingsFeature {
    static func isEnabled(arguments: [String] = CommandLine.arguments) -> Bool {
        !arguments.contains("--legacy-settings")
    }
}
