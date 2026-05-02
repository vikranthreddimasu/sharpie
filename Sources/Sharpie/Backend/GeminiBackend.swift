import Foundation

/// Wraps the `gemini` CLI in non-interactive (`--prompt`) mode. Uses the
/// user's existing Gemini CLI auth (Google AI Studio key or OAuth).
///
/// Verified against Gemini CLI 0.40.1 on 2026-05-01:
///
///     gemini -p "<combined system + user>" -o text
///
/// Gemini doesn't expose a separate `--system-prompt` flag, so we fold the
/// system prompt and user input together with a clear delimiter. The model
/// receives both as a single message; the system prompt's "rewrite the
/// following lazy prompt" instruction is what keeps roles straight.
struct GeminiBackend: AIToolBackend {
    let id: BackendID = .gemini
    let displayName: String = "Gemini"

    let executablePath: String
    let model: String?

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let combined = """
                    \(systemPrompt)

                    ---

                    User input to sharpen:
                    \(userInput)
                    """
                    var arguments: [String] = [
                        "-p", combined,
                        "-o", "text",
                        // Skip the workspace-trust dialog (interactive only;
                        // belt-and-suspenders alongside `-p`).
                        "--skip-trust",
                        // Default approval mode is "prompt for approval" —
                        // we don't want any interactive gate. `default` here
                        // is fine since `-p` already implies headless.
                        "--approval-mode", "default"
                    ]
                    if let model, !model.isEmpty {
                        arguments.append(contentsOf: ["-m", model])
                    }
                    let result = try await SubprocessRunner.run(
                        executablePath: executablePath,
                        arguments: arguments
                    )
                    if result.exitCode != 0 {
                        continuation.finish(throwing: SharpieError.backendFailed(
                            backend: .gemini,
                            exitCode: result.exitCode,
                            stderr: result.stderr
                        ))
                        return
                    }
                    let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        continuation.finish(throwing: SharpieError.backendEmptyResponse(backend: .gemini))
                        return
                    }
                    continuation.yield(trimmed)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
