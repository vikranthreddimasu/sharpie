import Foundation

// OpenRouter exposes an OpenAI-compatible Chat Completions endpoint at
// /api/v1/chat/completions. Streaming follows the OpenAI SSE shape:
// `data: {"choices":[{"delta":{"content":"..."}}]}` per chunk, with a
// final `data: [DONE]`. The HTTP-Referer / X-Title headers are how
// OpenRouter attributes traffic to a project — they're optional but
// polite and make the dashboard readable.
struct OpenRouterProvider: LLMProvider {
    let apiKey: String
    let model: String
    let maxTokens: Int

    var displayName: String { "OpenRouter — \(model)" }

    init(apiKey: String, model: String, maxTokens: Int = 1024) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
    }

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [apiKey, model, maxTokens] in
                do {
                    var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    req.setValue("https://github.com/vikranthreddimasu/sharpie", forHTTPHeaderField: "HTTP-Referer")
                    req.setValue("Sharpie", forHTTPHeaderField: "X-Title")
                    req.timeoutInterval = 60

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": maxTokens,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userInput]
                        ]
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
                        let message = OpenRouterProvider.extractMessage(from: trimmed) ?? trimmed
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

                        // OpenRouter sometimes emits an `error` envelope
                        // mid-stream — surface it instead of silently
                        // hanging on an empty stream.
                        if let err = event["error"] as? [String: Any],
                           let message = err["message"] as? String {
                            throw SharpieError.apiError(status: 0, message: message)
                        }

                        if let choices = event["choices"] as? [[String: Any]],
                           let first = choices.first,
                           let delta = first["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
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

    /// Best-effort message extraction. OpenRouter wraps errors as
    /// `{"error":{"message":"..."}}` most of the time, occasionally as
    /// `{"message":"..."}`, sometimes as a bare HTML error page during
    /// outages.
    private static func extractMessage(from body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let inner = json["error"] as? [String: Any], let message = inner["message"] as? String {
            return message
        }
        if let message = json["message"] as? String {
            return message
        }
        return nil
    }
}
