import Foundation

// Curated, hand-picked catalog of models we recommend for Sharpie. Not
// the full Ollama library — just the slice that's good for sharpening
// developer prompts. One file edit to add or replace anything.
enum OllamaCatalog {

    enum Category: String, CaseIterable, Identifiable {
        case coding = "Coding"
        case general = "General"
        case smallFast = "Small & fast"

        var id: String { rawValue }

        var hint: String {
            switch self {
            case .coding:    return "Tuned on code; best at sharpening developer prompts."
            case .general:   return "All-around models with broad knowledge."
            case .smallFast: return "Run on lower-RAM Macs and respond instantly."
            }
        }
    }

    struct Model: Identifiable, Hashable, Sendable {
        let slug: String          // what to pass to `ollama pull`
        let displayName: String
        let category: Category
        let approxSizeBytes: Int64
        let blurb: String
        let recommended: Bool

        var id: String { slug }

        var displaySize: String {
            let f = ByteCountFormatter()
            f.allowedUnits = [.useGB, .useMB]
            f.countStyle = .file
            return f.string(fromByteCount: approxSizeBytes)
        }
    }

    static let models: [Model] = [
        // Coding
        Model(
            slug: "qwen2.5-coder:7b",
            displayName: "Qwen 2.5 Coder · 7B",
            category: .coding,
            approxSizeBytes: 4_700_000_000,
            blurb: "Sharpie's recommended starter. Strong on code, runs fast on 16 GB Macs.",
            recommended: true
        ),
        Model(
            slug: "qwen2.5-coder:32b",
            displayName: "Qwen 2.5 Coder · 32B",
            category: .coding,
            approxSizeBytes: 19_000_000_000,
            blurb: "Top open coder. Needs ~24 GB RAM for comfortable inference.",
            recommended: false
        ),
        Model(
            slug: "deepseek-r1:7b",
            displayName: "DeepSeek R1 · 7B",
            category: .coding,
            approxSizeBytes: 4_700_000_000,
            blurb: "Reasoning-tuned. Slower but better at multi-step refinement.",
            recommended: false
        ),
        Model(
            slug: "codestral:22b",
            displayName: "Codestral · 22B",
            category: .coding,
            approxSizeBytes: 13_000_000_000,
            blurb: "Mistral's coding model. Solid on refactor / explain prompts.",
            recommended: false
        ),

        // General
        Model(
            slug: "llama3.3:70b",
            displayName: "Llama 3.3 · 70B",
            category: .general,
            approxSizeBytes: 40_000_000_000,
            blurb: "Frontier-class quality. Needs a Mac with ≥48 GB unified memory.",
            recommended: false
        ),
        Model(
            slug: "qwen2.5:7b",
            displayName: "Qwen 2.5 · 7B",
            category: .general,
            approxSizeBytes: 4_700_000_000,
            blurb: "Well-rounded general-purpose model. Good fallback for non-code prompts.",
            recommended: false
        ),
        Model(
            slug: "mistral-nemo:12b",
            displayName: "Mistral Nemo · 12B",
            category: .general,
            approxSizeBytes: 7_100_000_000,
            blurb: "Mistral's general-purpose model. Strong on long-context tasks.",
            recommended: false
        ),
        Model(
            slug: "gemma2:9b",
            displayName: "Gemma 2 · 9B",
            category: .general,
            approxSizeBytes: 5_400_000_000,
            blurb: "Google's open model. Friendly tone, broad knowledge.",
            recommended: false
        ),

        // Small & fast
        Model(
            slug: "phi3:mini",
            displayName: "Phi 3 mini",
            category: .smallFast,
            approxSizeBytes: 2_300_000_000,
            blurb: "Surprisingly capable for its size. Fast even on 8 GB Macs.",
            recommended: false
        ),
        Model(
            slug: "gemma2:2b",
            displayName: "Gemma 2 · 2B",
            category: .smallFast,
            approxSizeBytes: 1_600_000_000,
            blurb: "The smallest sensible choice. Use when memory is tight.",
            recommended: false
        )
    ]

    static var byCategory: [(Category, [Model])] {
        Category.allCases.map { cat in
            (cat, models.filter { $0.category == cat })
        }
    }

    static var defaultStarter: Model? {
        models.first { $0.recommended } ?? models.first
    }
}
