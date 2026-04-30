import Foundation

// One protocol — two future conformers. v0.1 is Anthropic only; v0.2 brings
// OpenRouter behind the same interface (per CLAUDE.md). The factory lets the
// rest of the app stay protocol-blind.
enum ProviderFactory {
    /// Returns the configured provider, or throws if no API key is available.
    /// Falls back to the `ANTHROPIC_API_KEY` environment variable when the
    /// Keychain is empty — convenient for `swift run` during development.
    static func makeDefault() throws -> any LLMProvider {
        if let key = KeychainService.get(.anthropic), !key.isEmpty {
            return AnthropicProvider(apiKey: key)
        }
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            return AnthropicProvider(apiKey: envKey)
        }
        throw SharpieError.missingAPIKey
    }
}
