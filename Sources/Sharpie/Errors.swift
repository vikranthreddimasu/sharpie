import Foundation

enum SharpieError: LocalizedError {
    case missingAPIKey(provider: ProviderID)
    case promptResourceNotFound
    case invalidResponse
    case apiError(status: Int, message: String)
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "No \(provider.displayName) API key set. Open Sharpie's menu → Settings… and add it."
        case .promptResourceNotFound:
            return "Couldn't load the system prompt. Reinstall Sharpie."
        case .invalidResponse:
            return "Got a response Sharpie didn't understand."
        case .apiError(let status, let message):
            if status == 0 { return message }
            return "Provider error (\(status)): \(message)"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}
