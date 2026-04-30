import Foundation

struct OpenRouterModel: Identifiable, Hashable, Sendable {
    let id: String           // "anthropic/claude-sonnet-4.5"
    let name: String         // human-friendly name from OpenRouter
}

@MainActor
final class OpenRouterModelDirectory: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([OpenRouterModel])
        case failed(String)
    }

    @Published var state: LoadState = .idle

    func fetch() async {
        if case .loading = state { return }
        state = .loading
        do {
            var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
            req.httpMethod = "GET"
            // OpenRouter publishes /models without auth — we just want the
            // attribution headers so the dashboard shows "Sharpie" if the
            // user later authenticates.
            req.setValue("https://github.com/vikranthreddimasu/sharpie", forHTTPHeaderField: "HTTP-Referer")
            req.setValue("Sharpie", forHTTPHeaderField: "X-Title")
            req.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed("HTTP \(http.statusCode)")
                return
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataArr = json["data"] as? [[String: Any]] else {
                state = .failed("Unexpected response shape")
                return
            }

            let models: [OpenRouterModel] = dataArr.compactMap { dict in
                guard let id = dict["id"] as? String else { return nil }
                let name = (dict["name"] as? String) ?? id
                return OpenRouterModel(id: id, name: name)
            }
            state = .loaded(models.sorted { $0.id < $1.id })
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Returns a sensible default model id given the loaded list. Always
    /// stays in the cheap-SOTA-open lane — Vikky explicitly does not want
    /// Sharpie auto-selecting Anthropic or OpenAI frontier slugs on his
    /// account. Order of preference: the canonical default, then any
    /// minimax m2 variant, then any recent Qwen, then DeepSeek, then any
    /// minimax, then a last-resort first-in-list.
    static func preferredDefault(in models: [OpenRouterModel]) -> String? {
        if let m = models.first(where: { $0.id == AppPreferences.defaultOpenRouterModel }) {
            return m.id
        }
        if let m = models.first(where: { $0.id.hasPrefix("minimax/") && $0.id.contains("m2") }) {
            return m.id
        }
        if let m = models.first(where: { $0.id.hasPrefix("qwen/") && $0.id.contains("3.6") }) {
            return m.id
        }
        if let m = models.first(where: { $0.id.hasPrefix("qwen/") && $0.id.contains("coder") }) {
            return m.id
        }
        if let m = models.first(where: { $0.id.hasPrefix("deepseek/") }) {
            return m.id
        }
        if let m = models.first(where: { $0.id.hasPrefix("minimax/") }) {
            return m.id
        }
        return models.first?.id
    }
}
