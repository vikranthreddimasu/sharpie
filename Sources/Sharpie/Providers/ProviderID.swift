import Foundation

enum ProviderID: String, CaseIterable, Codable, Identifiable, Sendable {
    case openrouter
    case ollama
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openrouter: return "OpenRouter"
        case .ollama:     return "Ollama"
        case .anthropic:  return "Anthropic"
        }
    }

    /// True for providers that need an API key in the Keychain. Ollama
    /// is a local server — no key required (an optional Bearer token
    /// is supported for users who put auth in front of their daemon,
    /// but it's not the common case).
    var requiresAPIKey: Bool {
        switch self {
        case .openrouter, .anthropic: return true
        case .ollama: return false
        }
    }
}
