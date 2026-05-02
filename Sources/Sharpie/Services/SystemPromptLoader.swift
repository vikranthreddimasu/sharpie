import Foundation

enum SystemPromptLoader {
    /// Load `prompts/sharpen.md` from the bundle. Throws if the resource
    /// is missing — that means the build is broken, not a runtime issue.
    static func load() throws -> String {
        guard let url = Bundle.module.url(forResource: "sharpen", withExtension: "md") else {
            throw SharpieError.promptResourceNotFound
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// Synchronous best-effort load with a hard-coded fallback. Used at app
    /// boot so the app can come up even if the bundle is corrupt.
    static func loadOrFallback() -> String {
        if let text = try? load(), !text.isEmpty { return text }
        return builtinFallback
    }

    /// Last-resort fallback when the resource bundle is missing entirely.
    /// Mirrors the contract in prompts/sharpen.md: rewrite-only, no
    /// clarifying questions ever. If the bundled prompt fails to load,
    /// every install would silently run on this string — it must not
    /// drift from the canonical contract.
    private static let builtinFallback = """
    You are Sharpie. Rewrite the user's lazy prompt as the prompt they should
    have typed for an AI coding tool. Output exactly one rewritten prompt in
    plain text. Imperative voice. Two to four short sentences. No preamble,
    no closing chatter, no quotes around the output.

    Never ask a clarifying question. If the input is short, vague, cryptic,
    or weird, still produce a rewrite — anchor it on what the receiving tool
    can see (open files, current selection, recent diffs, repo structure)
    and tell that tool to make a reasonable next move from its own context.
    The receiving tool can ask the user if it needs to.

    Mirror the developer's exact nouns. Never invent file paths, library
    names, frameworks, error messages, endpoints, or symptoms the developer
    didn't write. Generic + accurate beats specific + invented every time.
    """
}
