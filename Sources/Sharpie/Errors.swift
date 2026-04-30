import Foundation

enum SharpieError: LocalizedError {
    case missingAPIKey
    case promptResourceNotFound
    case invalidResponse
    case apiError(status: Int, message: String)
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key set. Open Sharpie's menu and add your Anthropic key."
        case .promptResourceNotFound:
            return "Couldn't load the system prompt. Reinstall Sharpie."
        case .invalidResponse:
            return "Got a response Sharpie didn't understand."
        case .apiError(let status, let message):
            return "Anthropic API error (\(status)): \(message)"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}
