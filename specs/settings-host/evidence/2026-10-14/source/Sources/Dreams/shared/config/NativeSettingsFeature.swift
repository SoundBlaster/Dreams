/// Explicit launch opt-in; absence always preserves the legacy settings route.
enum NativeSettingsFeature {
    static func isEnabled(arguments: [String] = CommandLine.arguments) -> Bool {
        arguments.contains("--native-settings") && !arguments.contains("--legacy-settings")
    }
}
