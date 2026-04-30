import Foundation

/// One model the local Ollama daemon has installed (output of `ollama list`).
struct OllamaModel: Identifiable, Hashable, Sendable {
    let id: String        // e.g. "llama3.1:latest", "qwen2.5-coder:32b"
    let sizeBytes: Int64?

    var name: String { id }

    var displaySize: String? {
        guard let sizeBytes else { return nil }
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useMB]
        f.countStyle = .file
        return f.string(fromByteCount: sizeBytes)
    }
}

@MainActor
final class OllamaModelDirectory: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([OllamaModel])
        case failed(String)
    }

    @Published var state: LoadState = .idle

    /// Hits `GET <baseURL>/api/tags` and parses out the installed models.
    /// 5-second timeout — local should respond fast or not at all.
    func fetch(baseURL: URL) async {
        state = .loading
        do {
            var req = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
            req.httpMethod = "GET"
            req.timeoutInterval = 5

            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed("HTTP \(http.statusCode)")
                return
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let modelsArr = json["models"] as? [[String: Any]]
            else {
                state = .failed("Unexpected response shape")
                return
            }
            let models: [OllamaModel] = modelsArr.compactMap { dict in
                guard let name = dict["name"] as? String else { return nil }
                let size: Int64?
                if let s = dict["size"] as? Int64 {
                    size = s
                } else if let s = dict["size"] as? Int {
                    size = Int64(s)
                } else {
                    size = nil
                }
                return OllamaModel(id: name, sizeBytes: size)
            }
            state = .loaded(models.sorted { $0.id < $1.id })
        } catch let urlError as URLError where urlError.code == .cannotConnectToHost
                                              || urlError.code == .cannotFindHost
                                              || urlError.code == .timedOut {
            state = .failed("Ollama not reachable at \(baseURL.absoluteString)")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
