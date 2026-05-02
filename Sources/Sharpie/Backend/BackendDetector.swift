import Foundation

/// Scans `$PATH` (plus a handful of common install locations the user's
/// `LSEnvironment` might not include when launched from Finder) for the
/// AI CLIs Sharpie can drive.
///
/// Why the extra dirs: a GUI-launched Mac app doesn't inherit the same
/// `$PATH` a Terminal session does. Tools installed via Homebrew end up
/// at `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel);
/// `npm -g` ends up under `~/.nvm/versions/node/*/bin` or similar; the
/// official Claude Code installer drops a binary at `~/.local/bin`.
/// We probe these regardless of whether they're on the inherited `$PATH`.
@MainActor
final class BackendDetector: ObservableObject {

    struct Detection: Identifiable, Equatable, Sendable {
        let id: BackendID
        let executablePath: String
        var displayName: String { id.displayName }
    }

    @Published private(set) var available: [Detection] = []
    @Published private(set) var hasScanned: Bool = false

    /// Run a fresh scan. Cheap (a few stat() calls). Safe to call on
    /// app launch and again whenever the user re-opens Settings.
    func scan() {
        var found: [Detection] = []
        for backend in BackendID.allCases {
            if let path = locate(backend.executableName) {
                found.append(Detection(id: backend, executablePath: path))
            }
        }
        self.available = found
        self.hasScanned = true
    }

    /// Find a backend by ID in the most recent scan results.
    func detection(for id: BackendID) -> Detection? {
        available.first { $0.id == id }
    }

    /// True if at least one supported CLI is installed and on a path we
    /// can reach.
    var hasAnyBackend: Bool { !available.isEmpty }

    // MARK: - Lookup

    /// Search order:
    ///   1. Each directory in inherited `$PATH`
    ///   2. A small allow-list of common install dirs that may not be on `$PATH`
    ///      when launched from Finder
    /// Returns the first existing, executable file at `<dir>/<name>`.
    private func locate(_ name: String) -> String? {
        let fm = FileManager.default
        var seen = Set<String>()
        for dir in candidateDirectories() where seen.insert(dir).inserted {
            let candidate = (dir as NSString).appendingPathComponent(name)
            if fm.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    private func candidateDirectories() -> [String] {
        var dirs: [String] = []

        // 1) Inherited PATH
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"], !pathEnv.isEmpty {
            dirs.append(contentsOf: pathEnv.split(separator: ":").map(String.init))
        }

        // 2) Common install locations (Homebrew + user bin + asdf-style)
        let home = NSHomeDirectory()
        dirs.append(contentsOf: [
            "/opt/homebrew/bin",      // Apple Silicon Homebrew
            "/usr/local/bin",         // Intel Homebrew + many manual installs
            "\(home)/.local/bin",     // Claude Code's `~/.local/bin` install target
            "\(home)/.bun/bin",       // bun
            "\(home)/.cargo/bin",     // rust toolchains
            "\(home)/bin",            // miscellaneous user-managed
        ])

        // 3) Node version managers — list every Node bin dir we can find.
        // nvm: ~/.nvm/versions/node/<v>/bin
        let nvmRoot = "\(home)/.nvm/versions/node"
        if let entries = try? FileManager.default.contentsOfDirectory(atPath: nvmRoot) {
            for entry in entries {
                dirs.append("\(nvmRoot)/\(entry)/bin")
            }
        }

        return dirs
    }
}
