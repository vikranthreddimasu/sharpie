import Foundation

// One protocol — many conformers. The factory hides which provider is
// active from the rest of the app, so the viewmodel and views only ever
// talk to `LLMProvider`.
//
// Resolution order: Keychain key for the active provider, then matching
// env var (`OPENROUTER_API_KEY` / `ANTHROPIC_API_KEY`) for `swift run`
// development convenience.
enum ProviderFactory {
    static func makeDefault() throws -> any LLMProvider {
        switch AppPreferences.activeProvider {
        case .openrouter:
            if let key = nonEmpty(KeychainService.get(.openrouter)) {
                return OpenRouterProvider(apiKey: key, model: AppPreferences.openRouterModel)
            }
            if let key = envKey("OPENROUTER_API_KEY") {
                return OpenRouterProvider(apiKey: key, model: AppPreferences.openRouterModel)
            }
            throw SharpieError.missingAPIKey(provider: .openrouter)

        case .anthropic:
            if let key = nonEmpty(KeychainService.get(.anthropic)) {
                return AnthropicProvider(apiKey: key)
            }
            if let key = envKey("ANTHROPIC_API_KEY") {
                return AnthropicProvider(apiKey: key)
            }
            throw SharpieError.missingAPIKey(provider: .anthropic)
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }

    private static func envKey(_ name: String) -> String? {
        nonEmpty(ProcessInfo.processInfo.environment[name])
    }
}
