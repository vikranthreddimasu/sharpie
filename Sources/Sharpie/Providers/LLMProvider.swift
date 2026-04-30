import Foundation

// CLAUDE.md spells the protocol as `streamCompletion(systemPrompt:userInput:)
// -> AsyncStream<String>`. We use AsyncThrowingStream instead so that network
// and API errors surface to the UI rather than being silently swallowed —
// that's the only deviation. Callers iterate with `for try await` and catch.
protocol LLMProvider: Sendable {
    var displayName: String { get }
    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error>
}
