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

    // Cheap SOTA-open default. Vikky pays per token through OpenRouter and
    // explicitly does not want Sharpie defaulting to Anthropic Sonnet or
    // GPT-4-class models — minimax 2.7 hits 15/15 on the eval at a fraction
    // of the cost. The model picker lets users override.
    static let defaultOpenRouterModel = "minimax/minimax-m2.7"
}
