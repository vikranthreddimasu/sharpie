import Foundation

enum ProviderID: String, CaseIterable, Identifiable, Sendable {
    case openrouter
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openrouter: return "OpenRouter"
        case .anthropic: return "Anthropic"
        }
    }
}
