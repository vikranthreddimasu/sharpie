import Foundation

/// Wraps the `claude` CLI in non-interactive (`-p`) mode, streaming the
/// response token-by-token via `--output-format stream-json
/// --include-partial-messages`. Each NDJSON line is parsed; `text_delta`
/// events are extracted and yielded incrementally so the UI can render
/// the rewrite as it generates instead of buffering the whole response.
///
/// Verified against Claude Code 2.1.126 on 2026-05-02. Uses the user's
/// existing OAuth (Pro/Max) or `ANTHROPIC_API_KEY` from their shell —
/// Sharpie never touches credentials directly.
struct ClaudeCodeBackend: AIToolBackend {
    let id: BackendID = .claudeCode
    let displayName: String = "Claude Code"

    let executablePath: String
    let model: String?

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var arguments: [String] = [
                    "-p",
                    "--system-prompt", systemPrompt,
                    "--output-format", "stream-json",
                    "--include-partial-messages",
                    // `--verbose` is required by the CLI when using
                    // `-p` together with `--output-format stream-json`.
                    // It doesn't add prose noise to the JSON stream;
                    // it just enables the streaming path.
                    "--verbose",
                    // `--effort low` skips the interleaved-thinking phase
                    // some models do before answering (~10 thinking tokens
                    // ≈ 1–2s of TTFT). Prompt rewriting is a simple task
                    // and doesn't benefit from extra reasoning steps; skip
                    // them and start emitting the answer immediately.
                    "--effort", "low",
                    "--no-session-persistence",
                    "--disable-slash-commands",
                ]
                if let model, !model.isEmpty {
                    arguments.append(contentsOf: ["--model", model])
                }
                arguments.append(userInput)

                let stream = SubprocessRunner.runStreaming(
                    executablePath: executablePath,
                    arguments: arguments
                )

                var emittedAny = false
                var terminationStderr: String = ""
                var terminationCode: Int32 = 0

                do {
                    for try await item in stream {
                        switch item {
                        case .line(let line):
                            if let text = Self.extractTextDelta(from: line), !text.isEmpty {
                                emittedAny = true
                                continuation.yield(text)
                            }
                        case .termination(let code, let stderr):
                            terminationCode = code
                            terminationStderr = stderr
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    return
                }

                if terminationCode != 0 {
                    continuation.finish(throwing: SharpieError.backendFailed(
                        backend: .claudeCode,
                        exitCode: terminationCode,
                        stderr: terminationStderr
                    ))
                    return
                }
                if !emittedAny {
                    continuation.finish(throwing: SharpieError.backendEmptyResponse(backend: .claudeCode))
                    return
                }
                continuation.finish()
            }
        }
    }

    /// Parse one NDJSON line from `stream-json` and pull out a text delta
    /// if present. Filters out `thinking_delta` (interleaved-thinking
    /// tokens that some models emit before the final answer) and any
    /// non-text events. Returns `nil` for anything we should skip.
    private static func extractTextDelta(from line: String) -> String? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // Top-level event must be a stream_event carrying a
        // content_block_delta.
        guard json["type"] as? String == "stream_event",
              let event = json["event"] as? [String: Any],
              event["type"] as? String == "content_block_delta",
              let delta = event["delta"] as? [String: Any]
        else { return nil }

        // Only text_delta — drop thinking, signature, etc.
        guard delta["type"] as? String == "text_delta",
              let text = delta["text"] as? String
        else { return nil }

        return text
    }
}
