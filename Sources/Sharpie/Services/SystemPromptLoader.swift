import Foundation

enum SystemPromptLoader {
    static func load() throws -> String {
        try loadResource("sharpen")
    }

    /// Per-provider hook kept for future divergence (e.g., Ollama may
    /// benefit from a smaller prompt for local 3-7B models). For now
    /// every provider uses the canonical sharpen.md.
    static func load(for provider: ProviderID) -> String {
        if let text = try? loadResource("sharpen"), !text.isEmpty { return text }
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
