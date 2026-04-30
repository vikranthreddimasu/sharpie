import AppKit
import Foundation

/// Launches Ollama and waits until its HTTP daemon is reachable. The user
/// shouldn't have to think about whether the daemon is "running" — they
/// just hit ⌘/ and Sharpie figures it out.
///
/// Behavior:
/// 1. Probe `<baseURL>/api/tags` with a 1-second timeout.
/// 2. If reachable, return immediately.
/// 3. If not reachable AND the .app exists, launch it via NSWorkspace.
///    macOS sets up the daemon as part of the Ollama app's normal
///    startup; the menu-bar icon appears like the user double-clicked it.
/// 4. Poll until the daemon answers, with an overall timeout cap.
@MainActor
final class OllamaDaemonStarter: ObservableObject {
    enum Status: Equatable {
        case idle
        case probing
        case launching
        case waiting
        case ready
        case unreachable(reason: String)
    }

    @Published private(set) var status: Status = .idle

    /// Best-effort start. Doesn't throw — surfaces results via `status`
    /// so the SettingsView can render the right copy.
    func startIfNeeded(baseURL: URL, overallTimeout: TimeInterval = 12) async {
        // Already known good — skip the work.
        if case .ready = status { return }

        status = .probing
        if await isReachable(baseURL: baseURL, timeout: 1.0) {
            status = .ready
            return
        }

        guard OllamaInstallation.canAutoStart else {
            status = .unreachable(reason: "Ollama isn't installed.")
            return
        }

        status = .launching
        do {
            try await launchOllamaApp()
        } catch {
            status = .unreachable(reason: "Couldn't launch Ollama: \(error.localizedDescription)")
            return
        }

        status = .waiting
        let deadline = Date().addingTimeInterval(overallTimeout)
        while Date() < deadline {
            // 250ms between probes — fast enough to feel snappy, slow
            // enough that we don't hammer the system while the daemon
            // is still spinning up.
            try? await Task.sleep(nanoseconds: 250_000_000)
            if await isReachable(baseURL: baseURL, timeout: 1.0) {
                status = .ready
                return
            }
        }
        status = .unreachable(reason: "Ollama didn't come online in \(Int(overallTimeout))s.")
    }

    /// Probe without state mutation — used by callers who just want
    /// to know if the daemon answers right now.
    func isReachable(baseURL: URL, timeout: TimeInterval = 1.0) async -> Bool {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        req.httpMethod = "GET"
        req.timeoutInterval = timeout
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse {
                return (200..<300).contains(http.statusCode)
            }
            return false
        } catch {
            return false
        }
    }

    /// Launch the Ollama .app. Standard macOS open — the user sees
    /// Ollama's menu-bar icon appear, which is exactly what would happen
    /// if they double-clicked it.
    private func launchOllamaApp() async throws {
        guard let appURL = OllamaInstallation.appBundleURL else {
            throw NSError(
                domain: "ai.sharpie.OllamaDaemonStarter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Ollama.app not found in /Applications."]
            )
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false   // don't steal focus
        config.addsToRecentItems = false
        config.hides = true        // launch hidden — the daemon and
                                   // menu-bar icon are what we want,
                                   // not a foreground app window.
        _ = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
    }
}
