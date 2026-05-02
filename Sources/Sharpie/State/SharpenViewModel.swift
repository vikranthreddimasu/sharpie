import Foundation
import SwiftUI

@MainActor
final class SharpenViewModel: ObservableObject {

    enum Status: Equatable {
        case idle
        case needsSetup
        case working                 // submitted, no tokens yet
        case streaming               // tokens arriving live
        case copied                  // stream done, rewrite on clipboard
        case error(String)
    }

    @Published var input: String = ""
    @Published var output: String = ""
    @Published var status: Status = .idle
    /// Bumped when the input field should retake focus (e.g., after revert).
    @Published var inputFocusToken: Int = 0
    /// 0 → 1 during the morph animation. Driven by the view layer's
    /// `withAnimation` block so it isn't stored persistently here.
    @Published var sweepProgress: Double = 0
    /// Wall-clock seconds since submit. Used for the >3s ghost counter on
    /// the hairline. Polled lightly via Timer in working state.
    @Published var elapsed: TimeInterval = 0

    let systemPrompt: String
    private let historyStore: HistoryStore
    private let detector: BackendDetector

    private var streamTask: Task<Void, Never>?
    private var elapsedTimer: Timer?
    private var lastOriginalInput: String = ""
    private var currentHistoryEntryId: UUID?
    private var currentBackend: BackendID = .claudeCode
    private var submitStartedAt: Date?
    @Published private(set) var lastDuration: TimeInterval?

    /// Session-local rewrite cache. An identical (backend, model, system
    /// prompt, input) tuple returns instantly the second time. Cleared
    /// only when the app exits — survives window dismiss/reopen so the
    /// "I'm tweaking and resubmitting" flow stays fast.
    private struct CacheKey: Hashable {
        let backendID: BackendID
        let model: String
        let systemPromptHash: Int
        let input: String
    }
    private var sessionCache: [CacheKey: String] = [:]

    init(
        systemPrompt: String,
        historyStore: HistoryStore,
        detector: BackendDetector
    ) {
        self.systemPrompt = systemPrompt
        self.historyStore = historyStore
        self.detector = detector
    }

    var placeholder: String {
        "Type, then ⏎ to sharpen"
    }

    var isInputEditable: Bool {
        switch status {
        case .working, .streaming, .needsSetup: return false
        case .idle, .copied, .error: return true
        }
    }

    /// Hairline state derivation — single source of truth for the bottom
    /// indicator. Streaming and pre-token waiting both look like
    /// "working" to the hairline.
    var hairline: StateHairline.Mode {
        switch status {
        case .idle, .needsSetup: return .idle
        case .working, .streaming: return .working(elapsed: elapsed)
        case .copied: return .copied
        case .error: return .error
        }
    }

    func focusInput() {
        inputFocusToken &+= 1
    }

    /// True if at least one supported CLI is installed.
    private var hasUsableBackend: Bool {
        detector.hasAnyBackend
    }

    func windowDidOpen() {
        if case .working = status { return }
        if case .streaming = status { return }
        detector.scan()
        if !hasUsableBackend {
            status = .needsSetup
            input = ""
            output = ""
            return
        }
        if case .needsSetup = status { status = .idle }
        focusInput()
    }

    func windowDidClose() {
        streamTask?.cancel()
        streamTask = nil
        stopElapsedTimer()
        input = ""
        output = ""
        status = .idle
        sweepProgress = 0
        elapsed = 0
        lastOriginalInput = ""
        currentHistoryEntryId = nil
        submitStartedAt = nil
        lastDuration = nil
    }

    /// ⌘Z escape hatch. Pulls the original input back so the user can edit
    /// and re-run.
    func revertToOriginal() {
        guard !lastOriginalInput.isEmpty else { return }
        streamTask?.cancel()
        streamTask = nil
        stopElapsedTimer()
        input = lastOriginalInput
        output = ""
        status = .idle
        sweepProgress = 0
        elapsed = 0
        focusInput()
    }

    /// User edited the rewrite in place. Refresh the clipboard so paste
    /// always matches what's on screen.
    func userEditedOutput() {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ClipboardService.copy(trimmed)
    }

    func submit() {
        if case .needsSetup = status { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lastOriginalInput = trimmed
        let userInput = trimmed
        output = ""
        sweepProgress = 0

        guard let backend = resolveBackend() else {
            status = .needsSetup
            return
        }
        currentBackend = backend.id

        // Cache hit — instant copy, no subprocess spawn, no animation
        // (the cross-fade is in MorphSurface's transition between phases).
        let model = AppPreferences.model(for: currentBackend) ?? currentBackend.defaultModel ?? ""
        let key = CacheKey(
            backendID: currentBackend,
            model: model,
            systemPromptHash: systemPrompt.hashValue,
            input: userInput
        )
        if let cached = sessionCache[key] {
            lastDuration = 0
            output = cached
            ClipboardService.copy(cached)
            status = .copied
            recordHistoryIfEnabled(text: cached)
            return
        }

        lastDuration = nil
        submitStartedAt = Date()
        elapsed = 0
        startElapsedTimer()
        status = .working

        let prompt = systemPrompt
        let cacheKey = key
        streamTask = Task { [weak self] in
            guard let self else { return }
            await self.runStream(
                backend: backend,
                systemPrompt: prompt,
                userInput: userInput,
                cacheKey: cacheKey
            )
        }
    }

    /// Pick the user's preferred backend if installed, otherwise the first
    /// detected. Falls back to Sharpie's quality-first model default when
    /// the user hasn't picked one in Settings.
    private func resolveBackend() -> (any AIToolBackend)? {
        let detections = detector.available
        guard !detections.isEmpty else { return nil }
        let pref = AppPreferences.activeBackend
        let chosen = detections.first(where: { $0.id == pref }) ?? detections[0]
        let model = AppPreferences.model(for: chosen.id) ?? chosen.id.defaultModel
        switch chosen.id {
        case .claudeCode:
            return ClaudeCodeBackend(executablePath: chosen.executablePath, model: model)
        case .codex:
            return CodexBackend(executablePath: chosen.executablePath, model: model)
        case .gemini:
            return GeminiBackend(executablePath: chosen.executablePath, model: model)
        }
    }

    private func runStream(
        backend: any AIToolBackend,
        systemPrompt: String,
        userInput: String,
        cacheKey: CacheKey
    ) async {
        do {
            var accumulated = ""
            var firstChunkSeen = false
            for try await chunk in backend.streamCompletion(systemPrompt: systemPrompt, userInput: userInput) {
                if Task.isCancelled { return }
                accumulated += chunk
                if !firstChunkSeen {
                    firstChunkSeen = true
                    // Flip into streaming mode on the first delta — the
                    // user sees text start appearing instead of a blank
                    // pulse for the full round-trip duration.
                    status = .streaming
                }
                output = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            stopElapsedTimer()
            await finalize(text: accumulated, cacheKey: cacheKey)
        } catch is CancellationError {
            stopElapsedTimer()
        } catch let error as SharpieError {
            stopElapsedTimer()
            failWith(error.errorDescription ?? "Something went wrong.")
        } catch {
            stopElapsedTimer()
            failWith(error.localizedDescription)
        }
    }

    private func failWith(_ message: String) {
        output = ""
        status = .error(message)
        input = lastOriginalInput
        focusInput()
    }

    private func finalize(text: String, cacheKey: CacheKey) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            failWith("No response from the backend.")
            return
        }

        if let started = submitStartedAt {
            lastDuration = Date().timeIntervalSince(started)
        }
        submitStartedAt = nil

        output = trimmed
        ClipboardService.copy(trimmed)
        status = .copied
        sessionCache[cacheKey] = trimmed

        recordHistoryIfEnabled(text: trimmed)
    }

    private func recordHistoryIfEnabled(text: String) {
        guard AppPreferences.historyEnabled, !lastOriginalInput.isEmpty else { return }
        currentHistoryEntryId = historyStore.appendEntry(
            originalInput: lastOriginalInput,
            aiOutput: text,
            backend: currentBackend,
            modelSlug: AppPreferences.model(for: currentBackend) ?? currentBackend.defaultModel
        )
    }

    // MARK: - Elapsed timer

    /// Drives the `elapsed` publisher used by the >3s ghost counter on the
    /// hairline. ~10Hz is plenty — the counter renders to one decimal at most.
    private func startElapsedTimer() {
        stopElapsedTimer()
        let started = Date()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsed = Date().timeIntervalSince(started)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
}
