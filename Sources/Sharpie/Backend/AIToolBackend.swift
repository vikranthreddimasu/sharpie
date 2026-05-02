import Foundation

/// Protocol every AI CLI subprocess wrapper conforms to. The viewmodel only
/// ever talks to this protocol — adding a new backend is one new file.
///
/// In v2 the "stream" emits a single chunk with the full response, because
/// every backend is invoked with `--output-format text` and the full text
/// arrives at once. The protocol shape is preserved (rather than collapsing
/// to `func sharpen(...) -> String`) so we can wire in real token streaming
/// later without touching `SharpenViewModel`.
protocol AIToolBackend: Sendable {
    var id: BackendID { get }
    var displayName: String { get }

    /// Send the system + user prompt to the CLI and yield the response text.
    /// Errors flow through the throwing stream as `SharpieError` cases.
    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error>
}
