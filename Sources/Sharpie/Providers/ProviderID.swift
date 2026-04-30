import Foundation

enum ProviderID: String, CaseIterable, Codable, Identifiable, Sendable {
    case appleIntelligence
    case openrouter
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleIntelligence: return "Apple Intelligence"
        case .openrouter:        return "OpenRouter"
        case .anthropic:         return "Anthropic"
        }
    }

    /// Whether this provider needs an API key. Apple Intelligence runs on
    /// device — no key, no network — so the Settings UI hides the key
    /// entry block when it's selected.
    var requiresAPIKey: Bool {
        switch self {
        case .appleIntelligence: return false
        case .openrouter, .anthropic: return true
        }
    }
}
