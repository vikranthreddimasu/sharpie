import Foundation

// Small, deliberately-non-observable wrapper over UserDefaults. Settings
// are read once when a request starts and written when the user clicks
// Save in the settings panel — there's no need for live observation in
// v0.1.
enum AppPreferences {
    private enum Keys {
        static let activeProvider = "sharpie.activeProvider"
        static let openRouterModel = "sharpie.openRouterModel"
        static let hotkey = "sharpie.hotkey"
    }

    static var activeProvider: ProviderID {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.activeProvider) ?? ""
            if let stored = ProviderID(rawValue: raw) { return stored }
            // No saved preference yet. Prefer Apple Intelligence on a
            // capable Mac — it's free, on-device, and the install story is
            // "open the app and start typing". Fall back to OpenRouter
            // (BYOA, cheap-SOTA-open) on everything else.
            if ProviderFactory.isAppleIntelligenceReady { return .appleIntelligence }
            return .openrouter
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

    static var hotkey: KeyCombo {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.hotkey),
                  let combo = try? JSONDecoder().decode(KeyCombo.self, from: data)
            else { return .default }
            return combo
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: Keys.hotkey)
        }
    }
}

extension Notification.Name {
    /// Posted from SettingsView when the user saves a new hotkey. AppDelegate
    /// re-registers without an app restart.
    static let sharpieHotkeyDidChange = Notification.Name("ai.sharpie.hotkeyDidChange")
}
