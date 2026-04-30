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
        static let historyEnabled = "sharpie.historyEnabled"
        static let ollamaURL = "sharpie.ollamaURL"
        static let ollamaModel = "sharpie.ollamaModel"
    }

    static var activeProvider: ProviderID {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.activeProvider) ?? ""
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

    /// The local Ollama daemon's default bind address. Override in
    /// Settings if Ollama is running on a different port or a remote
    /// host behind a reverse proxy.
    static let defaultOllamaURL = "http://localhost:11434"

    /// Reasonable starter model for Sharpie's task — small, fast, and
    /// widely pre-pulled. The model picker shows whatever is actually
    /// installed; this is just the placeholder before a pick is made.
    static let defaultOllamaModel = "llama3.1:latest"

    static var ollamaURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.ollamaURL)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let stored, !stored.isEmpty { return stored }
            return defaultOllamaURL
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed, forKey: Keys.ollamaURL)
        }
    }

    static var ollamaModel: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.ollamaModel)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let stored, !stored.isEmpty { return stored }
            return defaultOllamaModel
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed, forKey: Keys.ollamaModel)
        }
    }

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

    /// History default-on. Vikky's call (CLAUDE.md said no history; this
    /// is a deliberate override). The Settings UI shows a Disable
    /// toggle for the privacy-strict.
    static var historyEnabled: Bool {
        get {
            // UserDefaults.bool returns false for missing keys; treat
            // "never set" as the default-on case by checking the object.
            if UserDefaults.standard.object(forKey: Keys.historyEnabled) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.historyEnabled)
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.historyEnabled) }
    }
}

extension Notification.Name {
    /// Posted from SettingsView when the user saves a new hotkey. AppDelegate
    /// re-registers without an app restart.
    static let sharpieHotkeyDidChange = Notification.Name("ai.sharpie.hotkeyDidChange")
}
