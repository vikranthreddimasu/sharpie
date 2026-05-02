import Foundation

/// Small, deliberately-non-observable wrapper over UserDefaults. Settings
/// are read once when a request starts and written when the user clicks
/// Save in the settings panel — there's no need for live observation in v2.
enum AppPreferences {
    private enum Keys {
        static let activeBackend = "sharpie.activeBackend"
        static let hotkey = "sharpie.hotkey"
        static let historyEnabled = "sharpie.historyEnabled"
        static func model(for backend: BackendID) -> String {
            "sharpie.model.\(backend.rawValue)"
        }
    }

    /// The user's preferred backend. May not actually be installed —
    /// `BackendDetector` is the source of truth for what's runnable.
    /// `nil` means "auto-pick the first available."
    static var activeBackend: BackendID? {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.activeBackend) ?? ""
            return BackendID(rawValue: raw)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: Keys.activeBackend)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeBackend)
            }
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

    /// User's chosen model for `backend`, or `nil` to use whatever default
    /// the CLI is configured with. Free-form string — model availability
    /// depends on the user's plan, so we don't gate on a known list.
    static func model(for backend: BackendID) -> String? {
        let raw = UserDefaults.standard.string(forKey: Keys.model(for: backend))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }

    static func setModel(_ value: String?, for backend: BackendID) {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: Keys.model(for: backend))
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.model(for: backend))
        }
    }

    /// History off by default in v2 (changed from v1 default-on). The
    /// Settings UI shows a toggle.
    static var historyEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.historyEnabled) == nil {
                return false
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
