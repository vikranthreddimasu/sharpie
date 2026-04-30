import Foundation

#if canImport(FoundationModels)
import FoundationModels

// Schema the on-device model fills in instead of free-text. Apple's
// runtime applies token-level constrained decoding from this struct, so
// the model literally cannot emit a preamble or break the rewrite/clarify
// invariant — both are guaranteed by the type, not by prose rules in a
// system prompt.
//
// `kind` is a discriminator the viewmodel currently doesn't read (the
// existing "ends-with-?" heuristic still classifies correctly thanks to
// the @Guide copy below), but it's part of the schema so the model has
// to commit to one of the two paths up front instead of straddling.
@available(macOS 26.0, *)
@Generable
struct SharpenResponse {
    @Generable
    enum Kind {
        case rewrite
        case clarify
    }

    @Guide(description: """
    Use 'rewrite' to give a sharper prompt the developer can paste into \
    their AI coding tool. Use 'clarify' only when the input is genuinely \
    uninterpretable — references something not in the message ("the thing \
    we talked about", "make it work like the mockup") or is so vague no \
    rewrite would be useful.
    """)
    let kind: Kind

    @Guide(description: """
    The text to show. For a 'rewrite': imperative voice, 2 to 3 short \
    sentences, no preamble, no quotes, no apologies. Mirror the \
    developer's exact words for file names, function names, and error \
    messages — never invent paths. End with a period. For a 'clarify': \
    one specific question, ending with '?'. No preamble.
    """)
    let text: String
}
#endif
