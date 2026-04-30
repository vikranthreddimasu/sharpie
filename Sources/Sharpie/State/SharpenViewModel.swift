import Foundation
import SwiftUI

@MainActor
final class SharpenViewModel: ObservableObject {

    enum Status: Equatable {
        case idle
        case needsSetup
        case streaming
        case copied
        case clarifying(question: String, original: String)
        case error(String)
    }

    @Published var input: String = ""
    @Published var output: String = ""
    @Published var status: Status = .idle
    /// Bumped when the input field should retake focus (e.g., after revert).
    @Published var inputFocusToken: Int = 0

    let systemPrompt: String

    private var streamTask: Task<Void, Never>?
    private var lastOriginalInput: String = ""
    private var hasAskedQuestion: Bool = false

    init(systemPrompt: String) {
        self.systemPrompt = systemPrompt
    }

    var placeholder: String {
        switch status {
        case .clarifying:
            return "Answer in one line, then Enter…"
        default:
            return "Type a lazy prompt, then Enter…"
        }
    }

    var statusLine: String {
        switch status {
        case .idle:
            return "⏎ to sharpen   ·   esc to dismiss"
        case .needsSetup:
            return "Add an API key to start"
        case .streaming:
            return "Sharpening…"
        case .copied:
            return "Copied   ·   ⏎ or esc to dismiss   ·   ⌘Z to undo"
        case .clarifying:
            return "Answer in one line, then ⏎"
        case .error:
            return "⏎ to retry   ·   esc to dismiss"
        }
    }

    private var hasAnyAPIKey: Bool {
        if KeychainService.get(.openrouter) != nil { return true }
        if KeychainService.get(.anthropic) != nil { return true }
        let env = ProcessInfo.processInfo.environment
        if let v = env["OPENROUTER_API_KEY"], !v.isEmpty { return true }
        if let v = env["ANTHROPIC_API_KEY"], !v.isEmpty { return true }
        return false
    }

    func focusInput() {
        inputFocusToken &+= 1
    }

    /// Called when the window is opened by the hotkey. Don't wipe the user's
    /// in-flight input mid-stream; only reset if we're between runs. If no
    /// provider key is configured, surface the empty-setup state so the user
    /// sees what to do instead of typing into a dead input.
    func windowDidOpen() {
        if case .streaming = status { return }
        if !hasAnyAPIKey {
            status = .needsSetup
            input = ""
            output = ""
            return
        }
        if case .needsSetup = status {
            status = .idle
        }
        focusInput()
    }

    /// Called when the window is dismissed. Cancels in-flight work and resets.
    func windowDidClose() {
        streamTask?.cancel()
        streamTask = nil
        input = ""
        output = ""
        status = .idle
        hasAskedQuestion = false
        lastOriginalInput = ""
    }

    /// ⌘Z escape hatch. Pulls the original input back into the field so the
    /// user can edit and re-run it.
    func revertToOriginal() {
        guard !lastOriginalInput.isEmpty else { return }
        streamTask?.cancel()
        streamTask = nil
        input = lastOriginalInput
        output = ""
        status = .idle
        hasAskedQuestion = false
        focusInput()
    }

    func submit() {
        if case .needsSetup = status { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Determine whether this submission is the original prompt or the
        // answer to a clarify question.
        let userInput: String
        if case .clarifying(let question, let original) = status {
            userInput = """
            Original prompt:
            \(original)

            Your previous question:
            \(question)

            The user's answer:
            \(trimmed)
            """
        } else {
            lastOriginalInput = trimmed
            userInput = trimmed
        }

        // Visually clear the field while the answer streams in.
        input = ""
        output = ""
        status = .streaming

        streamTask = Task { [weak self, systemPrompt] in
            guard let self else { return }
            await self.runStream(systemPrompt: systemPrompt, userInput: userInput)
        }
    }

    private func runStream(systemPrompt: String, userInput: String) async {
        do {
            let provider = try ProviderFactory.makeDefault()
            var accumulated = ""
            for try await chunk in provider.streamCompletion(systemPrompt: systemPrompt, userInput: userInput) {
                if Task.isCancelled { return }
                accumulated += chunk
                self.output = accumulated
            }
            finalize(text: accumulated)
        } catch is CancellationError {
            // Cancellation is silent — the user closed the window or hit ⌘Z.
        } catch let error as SharpieError {
            output = ""
            status = .error(error.errorDescription ?? "Something went wrong.")
            input = lastOriginalInput
            focusInput()
        } catch {
            output = ""
            status = .error(error.localizedDescription)
            input = lastOriginalInput
            focusInput()
        }
    }

    private func finalize(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            status = .error("No response from the provider.")
            input = lastOriginalInput
            focusInput()
            return
        }

        // Clarify path: only allowed once, and only when the entire output is
        // a single short interrogative sentence. Anything else is treated as
        // a rewrite — including rewrites that happen to end with a "?".
        if !hasAskedQuestion && looksLikeClarifyingQuestion(trimmed) {
            hasAskedQuestion = true
            status = .clarifying(question: trimmed, original: lastOriginalInput)
            output = ""
            input = ""
            focusInput()
            return
        }

        ClipboardService.copy(trimmed)
        output = trimmed
        status = .copied
    }

    private func looksLikeClarifyingQuestion(_ text: String) -> Bool {
        guard text.hasSuffix("?") else { return false }
        guard text.count <= 240 else { return false }
        // A clarify is one sentence. If there are interior sentence
        // terminators it's almost certainly a rewrite that happened to end
        // with a question.
        let body = text.dropLast()
        let interiorTerminators = body.filter { $0 == "." || $0 == "!" || $0 == "?" }
        return interiorTerminators.isEmpty
    }
}
