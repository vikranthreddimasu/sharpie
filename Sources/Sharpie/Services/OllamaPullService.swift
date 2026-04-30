import Foundation

/// Streams a model pull from Ollama and surfaces progress (bytes /
/// total + status text) so the catalog UI can show a real progress
/// bar instead of an indeterminate spinner.
@MainActor
final class OllamaPullService: ObservableObject {

    enum Phase: Equatable {
        case idle
        case starting
        case pullingManifest
        case downloading(layer: String, completed: Int64, total: Int64)
        case verifying
        case writing
        case finishing
        case finished
        case failed(String)

        var displayText: String {
            switch self {
            case .idle:                return ""
            case .starting:            return "Starting…"
            case .pullingManifest:     return "Pulling manifest…"
            case .downloading(_, let completed, let total):
                let pct = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
                return "Downloading… \(pct)%"
            case .verifying:           return "Verifying…"
            case .writing:             return "Writing manifest…"
            case .finishing:           return "Finishing…"
            case .finished:            return "Installed"
            case .failed(let msg):     return msg
            }
        }

        var fraction: Double? {
            if case .downloading(_, let completed, let total) = self, total > 0 {
                return Double(completed) / Double(total)
            }
            return nil
        }
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var modelName: String?

    private var task: Task<Void, Never>?

    func pull(model: String, baseURL: URL) {
        cancel()
        phase = .starting
        modelName = model
        task = Task { [weak self] in
            await self?.runPull(model: model, baseURL: baseURL)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if case .finished = phase { return }
        phase = .idle
        modelName = nil
    }

    var isActive: Bool {
        switch phase {
        case .idle, .finished, .failed: return false
        default: return true
        }
    }

    private func runPull(model: String, baseURL: URL) async {
        do {
            var req = URLRequest(url: baseURL.appendingPathComponent("api/pull"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 60 * 60   // big models take time

            let body: [String: Any] = ["model": model, "stream": true]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (bytes, response) = try await URLSession.shared.bytes(for: req)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                phase = .failed("HTTP \(http.statusCode)")
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty,
                      let data = trimmed.data(using: .utf8),
                      let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }

                if let err = event["error"] as? String {
                    phase = .failed(err)
                    return
                }

                let status = (event["status"] as? String) ?? ""
                phase = parsePhase(status: status, event: event)
                if case .finished = phase { return }
            }
            // Stream ended without an explicit "success" — treat as
            // finished if we made it through manifest + write phases.
            if case .failed = phase { return }
            phase = .finished
        } catch is CancellationError {
            phase = .idle
        } catch let urlError as URLError where urlError.code == .cannotConnectToHost {
            phase = .failed("Couldn't reach Ollama. Make sure the daemon is running.")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func parsePhase(status: String, event: [String: Any]) -> Phase {
        let lower = status.lowercased()
        if lower.contains("pulling manifest") { return .pullingManifest }
        if lower == "success" { return .finished }
        if lower.contains("verifying") { return .verifying }
        if lower.contains("writing manifest") { return .writing }
        if lower.contains("removing any unused layers") { return .finishing }
        if lower.contains("pulling") || lower.contains("downloading") {
            // Mid-stream: the event also has total/completed for the
            // current layer.
            let layer = (event["digest"] as? String) ?? status
            let total = (event["total"] as? Int64)
                ?? (event["total"] as? Int).map(Int64.init)
                ?? 0
            let completed = (event["completed"] as? Int64)
                ?? (event["completed"] as? Int).map(Int64.init)
                ?? 0
            return .downloading(layer: layer, completed: completed, total: total)
        }
        // Unknown status — keep whatever we had so the UI doesn't flicker.
        return phase
    }
}

/// Removes a model from Ollama via DELETE /api/delete. One-shot, no
/// progress — the daemon returns immediately.
@MainActor
enum OllamaRemoveService {
    static func remove(model: String, baseURL: URL) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/delete"))
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": model])
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SharpieError.apiError(status: http.statusCode, message: "Couldn't remove \(model).")
        }
    }
}
