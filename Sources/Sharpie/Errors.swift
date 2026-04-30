import Foundation

enum SharpieError: LocalizedError {
    case missingAPIKey(provider: ProviderID)
    case promptResourceNotFound
    case invalidResponse
    case apiError(status: Int, message: String)
    case networkError(underlying: Error)

    case appleIntelligenceUnsupportedOS
    case appleIntelligenceDeviceIneligible
    case appleIntelligenceNotEnabled
    case appleIntelligenceModelNotReady
    case appleIntelligenceGuardrail

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

        case .appleIntelligenceUnsupportedOS:
            return "Apple Intelligence requires macOS 26 (Tahoe) or later. Switch to OpenRouter or Anthropic in Settings."
        case .appleIntelligenceDeviceIneligible:
            return "This Mac doesn't support Apple Intelligence. Switch to OpenRouter or Anthropic in Settings."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is off. Turn it on in System Settings → Apple Intelligence & Siri, then try again."
        case .appleIntelligenceModelNotReady:
            return "Apple Intelligence is still downloading. Try again in a few minutes."
        case .appleIntelligenceGuardrail:
            return "Apple Intelligence's safety filter blocked this prompt. Rephrase, or switch to OpenRouter / Anthropic in Settings."
        }
    }
}
