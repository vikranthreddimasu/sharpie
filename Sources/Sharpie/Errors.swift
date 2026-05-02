import Foundation

enum SharpieError: LocalizedError {
    case promptResourceNotFound
    case noBackendAvailable
    case backendLaunchFailed(reason: String)
    case backendFailed(backend: BackendID, exitCode: Int32, stderr: String)
    case backendEmptyResponse(backend: BackendID)
    case backendTimedOut(seconds: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .promptResourceNotFound:
            return "Couldn't load the system prompt. Reinstall Sharpie."

        case .noBackendAvailable:
            return "No supported AI CLI found. Install Claude Code, Codex, or Gemini and try again."

        case .backendLaunchFailed(let reason):
            return "Couldn't launch the AI CLI: \(reason)"

        case .backendFailed(let backend, let exitCode, let stderr):
            // Surface the first useful line of stderr — most CLIs put the
            // human-readable error on the last non-empty line, but the
            // first line is usually fine and shorter for the toast.
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return "\(backend.displayName) exited with code \(exitCode)."
            }
            let firstLine = trimmed
                .split(whereSeparator: \.isNewline)
                .first
                .map(String.init) ?? trimmed
            return "\(backend.displayName) error: \(firstLine)"

        case .backendEmptyResponse(let backend):
            return "\(backend.displayName) returned nothing. Run `\(backend.executableName)` in your terminal to check that it's signed in."

        case .backendTimedOut(let seconds):
            return "Backend timed out after \(Int(seconds))s. Try again."
        }
    }
}
