import Foundation

enum SharpieError: LocalizedError {
    case missingAPIKey(provider: ProviderID)
    case promptResourceNotFound
    case invalidResponse
    case apiError(status: Int, message: String)
    case networkError(underlying: Error)

    case ollamaUnreachable(url: String)
    case ollamaInvalidURL(String)
    case ollamaModelMissing(String)

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

        case .ollamaUnreachable(let url):
            return "Couldn't reach Ollama at \(url). Run `ollama serve` or open the Ollama app, then try again."
        case .ollamaInvalidURL(let url):
            return "Invalid Ollama URL: \(url). Use something like http://localhost:11434."
        case .ollamaModelMissing(let model):
            return "Ollama doesn't have '\(model)' installed. Run `ollama pull \(model)` and try again."
        }
    }
}
