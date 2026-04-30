import Foundation

// Small, deliberately-non-observable wrapper over UserDefaults. Settings
// are read once when a request starts and written when the user clicks
// Save in the settings panel — there's no need for live observation in
// v0.1.
enum AppPreferences {
    private enum Keys {
        static let activeProvider = "sharpie.activeProvider"
        static let openRouterModel = "sharpie.openRouterModel"
    }

    static var activeProvider: ProviderID {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.activeProvider) ?? ""
            // OpenRouter is the v0.1 default so a brand-new install lands
            // on the BYOA-friendly path Vikky asked for.
            return ProviderID(rawValue: raw) ?? .openrouter
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.activeProvider)
        }
    }

    static var openRouterModel: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.openRouterModel)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let stored, !stored.isEmpty { return stored }
            return defaultOpenRouterModel
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed, forKey: Keys.openRouterModel)
        }
    }

    static let defaultOpenRouterModel = "anthropic/claude-sonnet-4.5"
}
