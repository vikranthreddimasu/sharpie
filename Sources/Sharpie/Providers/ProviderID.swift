import Foundation

enum ProviderID: String, CaseIterable, Codable, Identifiable, Sendable {
    case openrouter
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openrouter: return "OpenRouter"
        case .anthropic: return "Anthropic"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .openrouter, .anthropic: return true
        }
    }
}
