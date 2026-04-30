import Foundation

struct AnthropicProvider: LLMProvider {
    let apiKey: String
    let model: String
    let maxTokens: Int

    var displayName: String { "Anthropic — \(model)" }

    init(apiKey: String, model: String = "claude-sonnet-4-6", maxTokens: Int = 1024) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
    }

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [apiKey, model, maxTokens] in
                do {
                    var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    req.timeoutInterval = 60

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": maxTokens,
                        "stream": true,
                        "system": systemPrompt,
                        "messages": [["role": "user", "content": userInput]]
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else {
                        throw SharpieError.invalidResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line + "\n"
                            if errorBody.count > 4096 { break }
                        }
                        let trimmed = errorBody.trimmingCharacters(in: .whitespacesAndNewlines)
                        let message = AnthropicProvider.extractMessage(from: trimmed) ?? trimmed
                        throw SharpieError.apiError(status: http.statusCode, message: message)
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data:") else { continue }
                        let payload = String(line.dropFirst("data:".count))
                            .trimmingCharacters(in: .whitespaces)
                        guard !payload.isEmpty, payload != "[DONE]" else { continue }
                        guard let data = payload.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        if let type = event["type"] as? String, type == "content_block_delta",
                           let delta = event["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                        // We deliberately ignore message_start / content_block_start /
                        // ping / message_stop — none of them carry text we need to render.
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let urlError as URLError {
                    continuation.finish(throwing: SharpieError.networkError(underlying: urlError))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Pulls the human-readable text out of Anthropic's JSON error envelope.
    /// The error body looks like `{"type":"error","error":{"type":"...","message":"..."}}`.
    private static func extractMessage(from body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = json["error"] as? [String: Any],
              let message = inner["message"] as? String else { return nil }
        return message
    }
}
