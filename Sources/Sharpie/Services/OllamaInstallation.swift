import AppKit
import Foundation

/// Detects whether Ollama is installed on this Mac and, if so, where.
/// "Installed" means: there's an `Ollama.app` we can launch, or the
/// CLI is on PATH. Most users come from the official installer which
/// drops the .app in /Applications and a CLI symlink in /usr/local/bin.
enum OllamaInstallation {

    /// True if the user has Ollama installed in any form Sharpie
    /// can interact with — either the .app (auto-startable) or the
    /// CLI binary alone (Homebrew users).
    static var isInstalled: Bool {
        appBundleURL != nil || cliBinaryURL != nil
    }

    /// True if there's a launchable .app — only the .app path lets
    /// Sharpie auto-start the daemon via NSWorkspace. CLI-only
    /// installs require the user to run `ollama serve` themselves.
    static var canAutoStart: Bool {
        appBundleURL != nil
    }

    /// First .app we find, in preference order: /Applications, then
    /// the user's ~/Applications.
    static var appBundleURL: URL? {
        let candidates: [URL] = [
            URL(fileURLWithPath: "/Applications/Ollama.app"),
            FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/Ollama.app")
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// First CLI we find, in preference order: Homebrew (Apple
    /// Silicon, then Intel), then /usr/local/bin.
    static var cliBinaryURL: URL? {
        let candidates: [URL] = [
            URL(fileURLWithPath: "/opt/homebrew/bin/ollama"),
            URL(fileURLWithPath: "/usr/local/bin/ollama"),
            URL(fileURLWithPath: "/usr/bin/ollama")
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    /// Where to point users who don't have Ollama yet. The empty-state
    /// "Get Ollama" button opens this in their browser.
    static let downloadURL = URL(string: "https://ollama.com/download")!
}
