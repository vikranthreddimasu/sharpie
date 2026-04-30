import Foundation

// Local-first provider that talks to a running Ollama instance over its
// chat API. By default Sharpie expects ollama on http://localhost:11434
// (the daemon's default), but the URL is user-configurable so a remote
// instance behind a reverse proxy is fine too. No API key is required;
// an optional Bearer token can be set for users who put auth in front.
//
// Streaming: Ollama uses NDJSON (newline-delimited JSON), not SSE. Each
// line is one JSON event with `message.content` for the delta and a
// `done` flag on the last event.
struct OllamaProvider: LLMProvider {
    let baseURL: URL
    let model: String
    let apiKey: String?

    var displayName: String { "Ollama — \(model)" }

    init(baseURL: URL, model: String, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.model = model
        self.apiKey = apiKey
    }

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [baseURL, model, apiKey] in
                do {
                    var req = URLRequest(url: baseURL.appendingPathComponent("api/chat"))
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let apiKey, !apiKey.isEmpty {
                        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    }
                    // Local models can take a few seconds to load on the
                    // first call after startup; give the request time.
                    req.timeoutInterval = 120

                    let body: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user",   "content": userInput]
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
                        // Ollama returns 404 with `{"error":"model 'foo' not found"}`
                        // when the model isn't pulled yet — surface a clearer message.
                        if http.statusCode == 404,
                           let payload = OllamaProvider.extractError(from: trimmed),
                           payload.lowercased().contains("not found") {
                            throw SharpieError.ollamaModelMissing(model)
                        }
                        let message = OllamaProvider.extractError(from: trimmed) ?? trimmed
                        throw SharpieError.apiError(status: http.statusCode, message: message)
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty,
                              let data = trimmed.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        if let errorString = event["error"] as? String {
                            throw SharpieError.apiError(status: 0, message: errorString)
                        }

                        if let message = event["message"] as? [String: Any],
                           let content = message["content"] as? String,
                           !content.isEmpty {
                            continuation.yield(content)
                        }
                        if let done = event["done"] as? Bool, done {
                            break
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let urlError as URLError {
                    // Friendly messages for the cases people will actually hit:
                    // forgot to start `ollama serve`, typo'd the URL, etc.
                    switch urlError.code {
                    case .cannotConnectToHost,
                         .cannotFindHost,
                         .timedOut,
                         .networkConnectionLost:
                        continuation.finish(
                            throwing: SharpieError.ollamaUnreachable(url: baseURL.absoluteString)
                        )
                    default:
                        continuation.finish(throwing: SharpieError.networkError(underlying: urlError))
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Best-effort parse of Ollama's varied error envelope shapes.
    private static func extractError(from body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let error = json["error"] as? String { return error }
        if let inner = json["error"] as? [String: Any], let message = inner["message"] as? String {
            return message
        }
        return nil
    }
}
