import Foundation

/// UI text lives in `Localization/<language>.lproj/Localizable.strings`; English is the base.
enum Loc {
    static let languages = ["en", "ru"]

    /// `DREAMS_LANGUAGE=ru` forces a language (tests, screenshots); otherwise the system's preferences decide.
    private static let bundle: Bundle = {
        if let forced = ProcessInfo.processInfo.environment["DREAMS_LANGUAGE"],
           let forcedBundle = bundle(for: forced) { return forcedBundle }
        return Bundle.module
    }()

    static func bundle(for language: String) -> Bundle? {
        guard let path = Bundle.module.path(forResource: language, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    static func resource(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(key, bundle: .atURL(bundle.bundleURL))
    }

    static func string(_ key: String, in bundle: Bundle? = nil) -> String {
        (bundle ?? Self.bundle).localizedString(forKey: key, value: key, table: nil)
    }
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    let text = Loc.string(key)
    return arguments.isEmpty ? text : String(format: text, locale: Locale.current, arguments: arguments)
}

func settingsString(_ key: String.LocalizationValue) -> LocalizedStringResource { Loc.resource(key) }
