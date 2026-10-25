import Foundation

public enum InterfaceLanguage: String, CaseIterable, Hashable, Sendable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    public func localizationIdentifier(preferredLanguages: [String]) -> String {
        switch self {
        case .simplifiedChinese: return "zh-Hans"
        case .english: return "en"
        case .system:
            return Bundle.preferredLocalizations(from: ["en", "zh-Hans"],
                                                 forPreferences: preferredLanguages).first ?? "en"
        }
    }
}

public final class HandbookLocalization: @unchecked Sendable {
    public static let shared = HandbookLocalization()
    private let bundle: Bundle
    private let englishBundle: Bundle?
    private let lock = NSLock()
    private var activeBundle: Bundle?
    private var activeIdentifier: String

    public init(bundle: Bundle = .main, language: InterfaceLanguage = .system,
                preferredLanguages: [String] = Locale.preferredLanguages) {
        self.bundle = bundle
        englishBundle = Self.localizationBundle("en", in: bundle)
        let identifier = language.localizationIdentifier(preferredLanguages: preferredLanguages)
        let selected = Self.localizationBundle(identifier, in: bundle)
        activeBundle = selected ?? englishBundle
        activeIdentifier = selected == nil ? "en" : identifier
    }

    private static func localizationBundle(_ identifier: String, in bundle: Bundle) -> Bundle? {
        guard let url = bundle.url(forResource: identifier, withExtension: "lproj") else { return nil }
        return Bundle(url: url)
    }

    public func use(_ language: InterfaceLanguage, preferredLanguages: [String] = Locale.preferredLanguages) {
        let identifier = language.localizationIdentifier(preferredLanguages: preferredLanguages)
        let selected = Self.localizationBundle(identifier, in: bundle)
        lock.lock()
        activeBundle = selected ?? englishBundle
        activeIdentifier = selected == nil ? "en" : identifier
        lock.unlock()
    }

    public var locale: Locale {
        lock.lock()
        let identifier = activeIdentifier
        lock.unlock()
        return Locale(identifier: identifier)
    }

    public func string(forKey key: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let fallback = englishBundle?.localizedString(forKey: key, value: key, table: nil) ?? key
        return activeBundle?.localizedString(forKey: key, value: fallback, table: nil) ?? fallback
    }
}
