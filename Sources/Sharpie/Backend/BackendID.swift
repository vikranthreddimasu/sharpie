import Foundation

/// Identifier for one of the AI CLI tools Sharpie shells out to. v2 deliberately
/// drops the old `ProviderID` (openrouter / ollama / anthropic) — Sharpie no
/// longer talks to APIs directly; it borrows the user's already-authenticated
/// CLI session.
enum BackendID: String, CaseIterable, Codable, Identifiable, Sendable {
    case claudeCode
    case codex
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex:      return "Codex"
        case .gemini:     return "Gemini"
        }
    }

    /// The binary name we look for on `$PATH`.
    var executableName: String {
        switch self {
        case .claudeCode: return "claude"
        case .codex:      return "codex"
        case .gemini:     return "gemini"
        }
    }

    /// One-line install instruction shown in the no-CLI-found onboarding.
    var installHint: String {
        switch self {
        case .claudeCode: return "Install Claude Code: https://docs.claude.com/en/docs/claude-code/setup"
        case .codex:      return "Install Codex CLI: https://github.com/openai/codex"
        case .gemini:     return "Install Gemini CLI: https://github.com/google-gemini/gemini-cli"
        }
    }

    /// Deep-link to the CLI's official install docs. Used by the first-run
    /// setup screen's Install button. Opens in the user's default browser.
    var installURL: String {
        switch self {
        case .claudeCode: return "https://docs.claude.com/en/docs/claude-code/setup"
        case .codex:      return "https://github.com/openai/codex"
        case .gemini:     return "https://github.com/google-gemini/gemini-cli"
        }
    }

    /// Sharpie's implicit "best-for-most-tasks" model when the user hasn't
    /// picked one in Settings. We pin a quality default — prompt rewriting
    /// is the product, and users rarely tune their CLI config for this.
    /// Aliases (sonnet/haiku/opus, gemini-2.5-pro) auto-resolve to the
    /// latest version in each family, so Sharpie doesn't need to track
    /// dated model IDs. `nil` means "don't pass --model" — used when
    /// there's no good "best" to commit to.
    var defaultModel: String? {
        switch self {
        case .claudeCode: return "sonnet"             // alias → latest Sonnet 4.x
        case .codex:      return nil                  // codex alias surface unstable
        case .gemini:     return "gemini-2.5-pro"     // latest Pro tier
        }
    }

    /// Curated picker options — one entry per model family, latest version
    /// only. Aliases (sonnet/haiku/opus, gemini-2.5-pro) auto-resolve to
    /// the latest version in each family, so the picker stays current
    /// without app updates.
    ///
    /// First entry is the implicit default (saved as nil so a future
    /// alias change in this enum propagates without UserDefaults migration).
    var modelOptions: [(label: String, value: String?)] {
        switch self {
        case .claudeCode:
            return [
                ("Sonnet (default)", nil),
                ("Opus", "opus"),
                ("Haiku", "haiku"),
            ]
        case .gemini:
            return [
                ("2.5 Pro (default)", nil),
                ("2.5 Flash", "gemini-2.5-flash"),
            ]
        case .codex:
            return [
                ("Default", nil),
            ]
        }
    }
}
