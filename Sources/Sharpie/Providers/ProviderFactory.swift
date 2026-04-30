import Foundation

// One protocol — many conformers. The factory hides which provider is
// active from the rest of the app, so the viewmodel and views only ever
// talk to `LLMProvider`.
//
// Resolution order: Keychain key for the active provider, then matching
// env var (`OPENROUTER_API_KEY` / `ANTHROPIC_API_KEY`) for `swift run`
// development convenience. Apple Intelligence has no key — it just needs
// to be available at the OS level.
enum ProviderFactory {
    static func makeDefault() throws -> any LLMProvider {
        switch AppPreferences.activeProvider {
        case .appleIntelligence:
            #if canImport(FoundationModels)
            if #available(macOS 26.0, *) {
                switch AppleIntelligenceProvider.status {
                case .ready:              return AppleIntelligenceProvider()
                case .deviceIneligible:   throw SharpieError.appleIntelligenceDeviceIneligible
                case .notEnabled:         throw SharpieError.appleIntelligenceNotEnabled
                case .modelNotReady:      throw SharpieError.appleIntelligenceModelNotReady
                case .unknown:            throw SharpieError.appleIntelligenceModelNotReady
                }
            }
            throw SharpieError.appleIntelligenceUnsupportedOS
            #else
            throw SharpieError.appleIntelligenceUnsupportedOS
            #endif

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

    /// True when Apple Intelligence is usable right now — Settings, the
    /// first-run flow, and the empty-state view all branch on this.
    static var isAppleIntelligenceReady: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return AppleIntelligenceProvider.isReady
        }
        #endif
        return false
    }

    /// True when Apple Intelligence is even an option on this build × OS.
    /// Drives whether the provider appears in the Settings picker at all.
    static var isAppleIntelligenceSupported: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return true
        }
        #endif
        return false
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }

    private static func envKey(_ name: String) -> String? {
        nonEmpty(ProcessInfo.processInfo.environment[name])
    }
}
