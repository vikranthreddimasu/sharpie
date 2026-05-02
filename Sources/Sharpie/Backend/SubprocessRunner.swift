import Foundation

/// Sendable-safe shared mutable state for the parallel pipe-reader pattern.
/// The DispatchGroup ensures both writes complete before notify reads them,
/// so concurrent access is fine — but the Swift 6 checker can't see the
/// happens-before relationship through GCD primitives. A `final class` with
/// `@unchecked Sendable` is the minimal, locally-scoped suppression.
private final class Buffers: @unchecked Sendable {
    var stdout: Data = Data()
    var stderr: Data = Data()
}

/// Shared helper for invoking an AI CLI as a one-shot subprocess. Each
/// invocation runs in a fresh empty temp directory so per-project config
/// (e.g. the user's project `CLAUDE.md`, `.claude/settings.json`,
/// `.gemini/`, etc.) doesn't leak into Sharpie's prompt rewriting context.
enum SubprocessRunner {

    struct Result {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// Default per-invocation timeout. A real CLI call to `claude -p` takes
    /// ~5–15s on Sonnet/Haiku; a hung process with no timeout would freeze
    /// the prompt window indefinitely. 60s is generous for slow networks
    /// and Opus warm-ups but short enough that the user notices.
    static let defaultTimeoutSeconds: TimeInterval = 60

    /// Run `executable` with `arguments`, capture stdout/stderr, return when
    /// the process exits. The temp cwd is created before launch and removed
    /// after exit so we don't leak directories. If the process doesn't exit
    /// within `timeout`, it's terminated and `SharpieError.backendTimedOut`
    /// is thrown.
    ///
    /// - Throws: `SharpieError.backendLaunchFailed` if the subprocess can't
    ///   even start (binary not found, permission error).
    /// - Throws: `SharpieError.backendTimedOut` if the process exceeds the
    ///   timeout.
    /// - Returns: Non-zero exits are returned as a `Result`, not thrown —
    ///   backends decide how to classify them.
    static func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        timeout: TimeInterval = defaultTimeoutSeconds
    ) async throws -> Result {

        // Hermetic cwd: Claude Code in particular auto-loads `CLAUDE.md` and
        // `.claude/settings.json` from cwd. Running from an empty temp dir
        // means Sharpie's invocations are isolated from the user's projects.
        let tempCwd = FileManager.default.temporaryDirectory
            .appendingPathComponent("sharpie-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: tempCwd, withIntermediateDirectories: true)
        } catch {
            throw SharpieError.backendLaunchFailed(reason: "Couldn't create temp directory: \(error.localizedDescription)")
        }
        defer {
            try? FileManager.default.removeItem(at: tempCwd)
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            process.currentDirectoryURL = tempCwd

            // Inherit the user's full environment — that's where the CLIs
            // find their auth tokens, config dirs, and Node version managers.
            // Caller can override individual keys via `environment`.
            var env = ProcessInfo.processInfo.environment
            if let environment {
                for (k, v) in environment { env[k] = v }
            }
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            // Disconnect stdin entirely so the CLI doesn't block waiting for
            // input when invoked in --print / -p mode.
            process.standardInput = FileHandle.nullDevice

            // Read pipes off the main thread; both reads must complete before
            // we resume the continuation, otherwise the subprocess can fill
            // a pipe buffer (~64KB) and deadlock waiting for it to drain.
            // Use a Sendable-safe box so the concurrently-executing closures
            // (the two reads + the termination handler) share state without
            // tripping Swift's strict-concurrency checker.
            let buffers = Buffers()
            let group = DispatchGroup()

            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                buffers.stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                buffers.stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                group.leave()
            }

            // Latch ensures the continuation is resumed exactly once. The
            // termination handler resumes on normal exit; the timeout
            // resumes if it fires first; whichever runs first wins.
            let resumed = ResumeLatch()

            process.terminationHandler = { proc in
                group.notify(queue: .global(qos: .userInitiated)) {
                    guard resumed.consume() else { return }
                    let result = Result(
                        stdout: String(data: buffers.stdout, encoding: .utf8) ?? "",
                        stderr: String(data: buffers.stderr, encoding: .utf8) ?? "",
                        exitCode: proc.terminationStatus
                    )
                    continuation.resume(returning: result)
                }
            }

            do {
                try process.run()
            } catch {
                if resumed.consume() {
                    continuation.resume(throwing: SharpieError.backendLaunchFailed(reason: error.localizedDescription))
                }
                return
            }

            // Timeout: terminate the still-running process and resume the
            // continuation with a timeout error. If the process already
            // exited, the latch has been consumed and this no-ops.
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeout) { [process] in
                guard resumed.consume() else { return }
                if process.isRunning { process.terminate() }
                continuation.resume(throwing: SharpieError.backendTimedOut(seconds: timeout))
            }
        }
    }
}

/// Tiny one-shot latch — the first caller to `consume()` gets `true`,
/// subsequent calls get `false`. Used to ensure a CheckedContinuation is
/// resumed exactly once when both a normal exit and a timeout race.
private final class ResumeLatch: @unchecked Sendable {
    private var fired = false
    private let lock = NSLock()
    func consume() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

extension SubprocessRunner {

    /// Streamed variant: yields stdout lines as they arrive instead of
    /// buffering the whole output. The process termination + final exit
    /// code lands as a `Termination` element on the stream right before
    /// `.finish()` so the caller can distinguish "closed normally" from
    /// "exited non-zero." Stderr is buffered until termination and
    /// included in `Termination.stderr`.
    enum StreamItem: Sendable {
        case line(String)
        case termination(exitCode: Int32, stderr: String)
    }

    /// Identical hermetic-cwd discipline to `run(...)` — fresh temp dir
    /// per invocation, removed on completion. Caller iterates the stream
    /// to receive each stdout line live; terminal `.termination` is
    /// always the last item before the stream finishes.
    static func runStreaming(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        timeout: TimeInterval = defaultTimeoutSeconds
    ) -> AsyncThrowingStream<StreamItem, Error> {

        AsyncThrowingStream { continuation in
            let tempCwd = FileManager.default.temporaryDirectory
                .appendingPathComponent("sharpie-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: tempCwd, withIntermediateDirectories: true)
            } catch {
                continuation.finish(throwing: SharpieError.backendLaunchFailed(
                    reason: "Couldn't create temp directory: \(error.localizedDescription)"
                ))
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            process.currentDirectoryURL = tempCwd

            var env = ProcessInfo.processInfo.environment
            if let environment {
                for (k, v) in environment { env[k] = v }
            }
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = FileHandle.nullDevice

            // Stdout: line-buffered. Each newline boundary triggers a
            // yield. Partial lines are held in `pending` until the
            // remainder arrives (or termination flushes them).
            let pending = LineBuffer()
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty { return }
                if let text = String(data: data, encoding: .utf8) {
                    for line in pending.feed(text) {
                        continuation.yield(.line(line))
                    }
                }
            }

            // Stderr: buffered until termination — small enough that we
            // don't need to stream it.
            let stderrBuffer = Buffers()
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty { return }
                stderrBuffer.appendStderr(data)
            }

            let resumed = ResumeLatch()

            process.terminationHandler = { proc in
                // Drain any final bytes after the kernel close.
                let leftoverOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                if !leftoverOut.isEmpty, let text = String(data: leftoverOut, encoding: .utf8) {
                    for line in pending.feed(text) {
                        continuation.yield(.line(line))
                    }
                }
                if let trailing = pending.flush() {
                    continuation.yield(.line(trailing))
                }
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                let leftoverErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if !leftoverErr.isEmpty {
                    stderrBuffer.appendStderr(leftoverErr)
                }

                guard resumed.consume() else { return }
                let stderr = String(data: stderrBuffer.stderr, encoding: .utf8) ?? ""
                continuation.yield(.termination(exitCode: proc.terminationStatus, stderr: stderr))
                continuation.finish()
                try? FileManager.default.removeItem(at: tempCwd)
            }

            do {
                try process.run()
            } catch {
                if resumed.consume() {
                    continuation.finish(throwing: SharpieError.backendLaunchFailed(reason: error.localizedDescription))
                }
                try? FileManager.default.removeItem(at: tempCwd)
                return
            }

            // Timeout — kills the process and finishes the stream.
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeout) { [process] in
                guard resumed.consume() else { return }
                if process.isRunning { process.terminate() }
                continuation.finish(throwing: SharpieError.backendTimedOut(seconds: timeout))
                try? FileManager.default.removeItem(at: tempCwd)
            }

            // Cancellation — stop the process if the consumer cancels.
            continuation.onTermination = { @Sendable termination in
                if case .cancelled = termination {
                    if process.isRunning { process.terminate() }
                }
            }
        }
    }
}

/// Splits a streaming byte feed into newline-terminated lines. Holds onto
/// the trailing partial line until the next chunk completes it (or the
/// final flush emits whatever remained).
private final class LineBuffer: @unchecked Sendable {
    private var carry: String = ""
    private let lock = NSLock()

    func feed(_ chunk: String) -> [String] {
        lock.lock(); defer { lock.unlock() }
        let combined = carry + chunk
        let parts = combined.split(separator: "\n", omittingEmptySubsequences: false)
        if parts.isEmpty {
            carry = ""
            return []
        }
        // The last component is either a complete line (if `combined`
        // ended with `\n`) or a partial line. Distinguish by re-checking
        // the last byte.
        let endedOnNewline = combined.hasSuffix("\n")
        if endedOnNewline {
            carry = ""
            return parts.map(String.init).filter { !$0.isEmpty }
        } else {
            carry = String(parts.last ?? "")
            return parts.dropLast().map(String.init).filter { !$0.isEmpty }
        }
    }

    /// Drain any unterminated trailing line. Called once on process exit.
    func flush() -> String? {
        lock.lock(); defer { lock.unlock() }
        let trailing = carry.trimmingCharacters(in: .whitespacesAndNewlines)
        carry = ""
        return trailing.isEmpty ? nil : trailing
    }
}

extension Buffers {
    fileprivate func appendStderr(_ data: Data) {
        stderr.append(data)
    }
}
