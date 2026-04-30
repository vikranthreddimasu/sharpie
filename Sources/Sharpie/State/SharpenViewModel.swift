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
    /// Bumped when the output editor should take focus (e.g., user clicked
    /// "Edit" on the output area).
    @Published var outputFocusToken: Int = 0
    /// True when the output area is in editable mode (user is tweaking the
    /// rewrite before pasting). False = rendered markdown view.
    @Published var outputEditing: Bool = false

    let systemPrompt: String
    private let historyStore: HistoryStore

    private var streamTask: Task<Void, Never>?
    private var lastOriginalInput: String = ""
    private var hasAskedQuestion: Bool = false
    /// The original AI output for the current rewrite, before the user
    /// edited it. Lets us compare and capture a revision when the user
    /// commits edits.
    private(set) var aiOriginalOutput: String = ""
    /// Identifier of the current history entry. Set when finalize() runs
    /// and is used to attach edit revisions later in the same session.
    private var currentHistoryEntryId: UUID?
    /// Provider + model at the moment of submit, captured so the history
    /// entry records what produced the rewrite.
    private var currentProvider: ProviderID = .openrouter
    private var currentModelSlug: String?

    init(systemPrompt: String, historyStore: HistoryStore) {
        self.systemPrompt = systemPrompt
        self.historyStore = historyStore
    }

    var placeholder: String {
        switch status {
        case .clarifying:
            return "Answer in one line, then Enter…"
        default:
            return "Type a lazy prompt, then Enter…"
        }
    }

    /// Locked while a rewrite is streaming so the user can read what they
    /// sent without accidentally typing into the input field.
    var isInputEditable: Bool {
        switch status {
        case .streaming, .needsSetup: return false
        case .idle, .copied, .clarifying, .error: return true
        }
    }

    var statusLine: String {
        if outputEditing {
            return "Editing   ·   ⌘Z to undo   ·   click Done or esc to save"
        }
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

    private var hasUsableProvider: Bool {
        if KeychainService.get(.openrouter) != nil { return true }
        if KeychainService.get(.anthropic) != nil { return true }
        let env = ProcessInfo.processInfo.environment
        if let v = env["OPENROUTER_API_KEY"], !v.isEmpty { return true }
        if let v = env["ANTHROPIC_API_KEY"], !v.isEmpty { return true }
        if ProviderFactory.isAppleIntelligenceReady { return true }
        return false
    }

    func focusInput() {
        inputFocusToken &+= 1
    }

    func focusOutput() {
        outputFocusToken &+= 1
    }

    /// Toggle the output area between rendered markdown view and editable
    /// plain-text mode. Called from the Edit/Done button in SharpenView.
    func toggleOutputEditing() {
        if outputEditing {
            commitOutputEdit()
        } else {
            outputEditing = true
            focusOutput()
        }
    }

    /// Persist whatever the user typed in the output editor: keep it in
    /// the clipboard, push a revision into the history store (if enabled
    /// and the text actually changed), and switch back to rendered view.
    func commitOutputEdit() {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        ClipboardService.copy(trimmed.isEmpty ? output : trimmed)
        if let entryId = currentHistoryEntryId, AppPreferences.historyEnabled, !trimmed.isEmpty {
            historyStore.appendRevision(entryId: entryId, text: trimmed)
        }
        outputEditing = false
    }

    /// Called when the window is opened by the hotkey. Don't wipe the user's
    /// in-flight input mid-stream; only reset if we're between runs. If no
    /// provider key is configured, surface the empty-setup state so the user
    /// sees what to do instead of typing into a dead input.
    func windowDidOpen() {
        if case .streaming = status { return }
        if !hasUsableProvider {
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
        // If the user dismissed mid-edit, treat it like a commit so the
        // final state still gets persisted.
        if outputEditing {
            commitOutputEdit()
        }
        streamTask?.cancel()
        streamTask = nil
        input = ""
        output = ""
        status = .idle
        hasAskedQuestion = false
        lastOriginalInput = ""
        aiOriginalOutput = ""
        outputEditing = false
        currentHistoryEntryId = nil
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
        let isClarifyAnswer: Bool
        if case .clarifying(let question, let original) = status {
            userInput = """
            Original prompt:
            \(original)

            Your previous question:
            \(question)

            The user's answer:
            \(trimmed)
            """
            isClarifyAnswer = true
        } else {
            lastOriginalInput = trimmed
            userInput = trimmed
            isClarifyAnswer = false
        }

        // For the original prompt: preserve the input field so the user
        // sees what they sent while the rewrite streams. For a clarify
        // answer: clear so the input doesn't show "src/auth.ts" while
        // the rewritten prompt streams in below.
        if isClarifyAnswer {
            input = ""
        }
        output = ""
        status = .streaming

        // Capture provider/model context for history attribution.
        currentProvider = AppPreferences.activeProvider
        currentModelSlug = (currentProvider == .openrouter)
            ? AppPreferences.openRouterModel
            : nil

        // Resolve the system prompt for the *currently selected*
        // provider — Apple Intelligence gets a smaller on-device-tuned
        // prompt, frontier API providers get the full one. Resolved at
        // submit time so a provider switch in Settings takes effect on
        // the next ⌘/, no app restart.
        let prompt = SystemPromptLoader.load(for: currentProvider)

        streamTask = Task { [weak self] in
            guard let self else { return }
            await self.runStream(systemPrompt: prompt, userInput: userInput)
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
        aiOriginalOutput = trimmed
        outputEditing = false
        status = .copied

        // Record the new entry. We only persist if history is enabled,
        // and only on the *original* prompt — not on a clarify answer
        // (the original is already attached to its own entry).
        if AppPreferences.historyEnabled && !lastOriginalInput.isEmpty {
            currentHistoryEntryId = historyStore.appendEntry(
                originalInput: lastOriginalInput,
                aiOutput: trimmed,
                provider: currentProvider,
                modelSlug: currentModelSlug
            )
        }
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
