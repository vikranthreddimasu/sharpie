import Foundation

/// Wraps the OpenAI Codex CLI in non-interactive mode. Uses the user's
/// existing ChatGPT login (or OPENAI_API_KEY from their shell).
///
/// **Note**: Codex CLI was not installed on the dev machine when this file
/// was written, so the exact flag syntax below is a best-effort match
/// against publicly documented invocation. The detector only surfaces this
/// backend if `codex` is on `$PATH` — users without Codex never see it.
/// If the syntax is wrong on a machine that has Codex installed, the
/// subprocess will exit non-zero and the user will see a clear error
/// pointing to this file.
///
/// Documented invocation (subject to verification):
///
///     codex exec --skip-git-repo-check "<combined system + user>"
struct CodexBackend: AIToolBackend {
    let id: BackendID = .codex
    let displayName: String = "Codex"

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
                        "exec",
                        "--skip-git-repo-check"
                    ]
                    if let model, !model.isEmpty {
                        arguments.append(contentsOf: ["-m", model])
                    }
                    arguments.append(combined)
                    let result = try await SubprocessRunner.run(
                        executablePath: executablePath,
                        arguments: arguments
                    )
                    if result.exitCode != 0 {
                        continuation.finish(throwing: SharpieError.backendFailed(
                            backend: .codex,
                            exitCode: result.exitCode,
                            stderr: result.stderr
                        ))
                        return
                    }
                    let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        continuation.finish(throwing: SharpieError.backendEmptyResponse(backend: .codex))
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
