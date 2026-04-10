import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spanish: LanguageManager.shared.current == .spanish ? "Castellano" : "Spanish"
        case .english: LanguageManager.shared.current == .spanish ? "Inglés" : "English"
        }
    }

    var code: String {
        rawValue.uppercased()
    }
}

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "app_language")
            UserDefaults.standard.set([current.rawValue], forKey: "AppleLanguages")
            bundle = Self.loadBundle(for: current)
            refreshId = UUID()
        }
    }

    private(set) var bundle: Bundle
    var refreshId = UUID()

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        let language = AppLanguage(rawValue: saved) ?? .english
        self.current = language
        self.bundle = Self.loadBundle(for: language)
    }

    func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static func loadBundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

// MARK: - View Extension

extension Text {
    init(localized key: String) {
        let value = LanguageManager.shared.localizedString(key)
        self.init(value)
    }
}
