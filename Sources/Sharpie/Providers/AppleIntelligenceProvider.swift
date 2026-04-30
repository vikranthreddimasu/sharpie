import Foundation

#if canImport(FoundationModels)
import FoundationModels

// On-device provider backed by Apple's Foundation Models framework. Free,
// private (no network), and zero-config — but only on Apple Silicon Macs
// running macOS 26 (Tahoe) with Apple Intelligence enabled.
//
// `#if canImport(FoundationModels)` keeps Sharpie buildable on older
// toolchains (Xcode 16 / macOS 15 SDK). When the framework isn't available
// at compile time, the rest of the app falls back to OpenRouter / Anthropic
// and the segmented picker hides this option.
//
// `@available(macOS 26.0, *)` gates runtime usage so a binary built with
// the macOS 26 SDK still launches and runs on macOS 14+ — the option just
// won't appear.
@available(macOS 26.0, *)
struct AppleIntelligenceProvider: LLMProvider {

    var displayName: String { "Apple Intelligence (on-device)" }

    /// Mirror of `SystemLanguageModel.Availability` collapsed into a stable
    /// enum the UI can switch on. Re-derived on every check — Apple
    /// Intelligence can be toggled in System Settings while Sharpie is
    /// running.
    enum Status: Equatable {
        case ready
        case deviceIneligible
        case notEnabled
        case modelNotReady
        case unknown
    }

    static var status: Status {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:           return .deviceIneligible
            case .appleIntelligenceNotEnabled: return .notEnabled
            case .modelNotReady:               return .modelNotReady
            @unknown default:                  return .unknown
            }
        }
    }

    static var isReady: Bool { status == .ready }

    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Re-check at call time — the user could have turned
                    // Apple Intelligence off between launch and now, or the
                    // model could still be downloading.
                    switch SystemLanguageModel.default.availability {
                    case .available:
                        break
                    case .unavailable(let reason):
                        throw Self.error(for: reason)
                    }

                    let session = LanguageModelSession {
                        systemPrompt
                    }

                    // Foundation Models streams *cumulative* partials
                    // wrapped in a Snapshot — not deltas. The rest of the
                    // app expects deltas (it does `accumulated += chunk`),
                    // so emit the suffix that's new since the previous
                    // partial.
                    var emitted = ""
                    for try await snapshot in session.streamResponse(to: userInput) {
                        if Task.isCancelled { break }
                        let str = snapshot.content
                        guard str.count > emitted.count else { continue }
                        let startIdx = str.index(
                            str.startIndex,
                            offsetBy: emitted.count,
                            limitedBy: str.endIndex
                        ) ?? str.endIndex
                        continuation.yield(String(str[startIdx...]))
                        emitted = str
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let genError as LanguageModelSession.GenerationError {
                    continuation.finish(throwing: Self.translate(genError))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func error(for reason: SystemLanguageModel.Availability.UnavailableReason) -> SharpieError {
        switch reason {
        case .deviceNotEligible:           return .appleIntelligenceDeviceIneligible
        case .appleIntelligenceNotEnabled: return .appleIntelligenceNotEnabled
        case .modelNotReady:               return .appleIntelligenceModelNotReady
        @unknown default:                  return .appleIntelligenceModelNotReady
        }
    }

    /// Apple's safety guardrails are stricter than typical API providers
    /// and can block legitimate developer phrasing ("kill the process",
    /// "exploit", etc.). When that happens, surface a message that points
    /// the user at the workaround (rephrase, or switch providers).
    private static func translate(_ error: LanguageModelSession.GenerationError) -> SharpieError {
        if case .guardrailViolation = error {
            return .appleIntelligenceGuardrail
        }
        return .apiError(status: 0, message: error.localizedDescription)
    }
}
#endif
