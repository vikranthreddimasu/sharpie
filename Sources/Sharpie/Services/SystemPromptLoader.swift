import Foundation

enum SystemPromptLoader {
    /// Backwards-compatible loader that returns the main frontier-model
    /// prompt. Used for fallbacks and the AppDelegate boot path.
    static func load() throws -> String {
        try loadResource("sharpen")
    }

    /// Pick the right system prompt for the active provider. Apple
    /// Intelligence runs a ~3B-parameter on-device model with a smaller
    /// context window and stricter safety guardrails — it gets a
    /// distilled prompt tuned to fit. Frontier API providers get the
    /// full 5KB prompt that's been validated 75/75 across model
    /// families.
    static func load(for provider: ProviderID) -> String {
        let primary: String
        let fallback: String
        switch provider {
        case .appleIntelligence:
            primary = "sharpen-on-device"
            fallback = "sharpen"
        case .openrouter, .anthropic:
            primary = "sharpen"
            fallback = "sharpen-on-device"
        }
        if let text = try? loadResource(primary), !text.isEmpty { return text }
        if let text = try? loadResource(fallback), !text.isEmpty { return text }
        return Self.builtinFallback
    }

    private static func loadResource(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "md") else {
            throw SharpieError.promptResourceNotFound
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private static let builtinFallback = """
    You are Sharpie. Rewrite the user's lazy prompt as the prompt they should
    have typed for an AI coding tool. Imperative voice, two to three short
    sentences, no preamble. If the input is genuinely uninterpretable, ask
    exactly one specific clarifying question ending with "?".
    """
}
