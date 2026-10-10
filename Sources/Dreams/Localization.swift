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

    static func string(_ key: String, in bundle: Bundle? = nil) -> String {
        (bundle ?? Self.bundle).localizedString(forKey: key, value: key, table: nil)
    }
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    let text = Loc.string(key)
    return arguments.isEmpty ? text : String(format: text, locale: Locale.current, arguments: arguments)
}

/// The short words a hook puts into the rain for events that have no tool call line.
enum HookWord: String, CaseIterable {
    case start, task, done, context, search, code, study, check, terminal, interface, delegate, work

    var text: String { Loc.string("hook." + rawValue) }

    /// True for the words of a session that has just started or finished, in any shipped language:
    /// the feed may hold words written under another language setting.
    static func isIdleMarker(_ words: [String]) -> Bool {
        Loc.languages.contains { language in
            guard let bundle = Loc.bundle(for: language) else { return false }
            return [HookWord.done, .start].contains { words == [Loc.string("hook." + $0.rawValue, in: bundle)] }
        }
    }
}
