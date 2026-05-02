import SwiftUI

/// The single text region that holds Sharpie's content through every state:
/// empty → typing → working → morphing → result. The morph between working
/// and result is the lightbar sweep — a 600ms left-to-right pass that
/// reveals the rewrite as it travels.
///
/// Two simultaneous text layers, partitioned by an animated mask:
///   - Behind the bar: the rewrite (revealed)
///   - Ahead of the bar: the input (still showing)
///   - At the boundary: the bar itself, a 4pt accent gradient with soft glow
///
/// Outside of the morph, only one text is visible at a time.
struct MorphSurface: View {

    enum Phase: Equatable {
        case input          // user is typing or staring at empty
        case working        // submitted, no tokens yet — input dimmed
        case streaming      // tokens arriving — output rendering live
        case result         // stream done, rewrite is editable in place
    }

    @Binding var input: String
    /// The rewrite or clarify question. Empty until backend returns.
    @Binding var output: String
    var phase: Phase
    /// Bumped when the input editor should retake focus.
    var inputFocusToken: Int
    /// Whether the user can type into the input field.
    var isInputEditable: Bool
    /// Placeholder shown only when input is empty AND the surface is in the
    /// .input phase. Disappears immediately on the first keystroke.
    var placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch phase {
            case .input:
                inputLayer
            case .working:
                // Input visible, dimmed, no output yet — the hairline pulse
                // carries the "we're working" signal.
                inputLayer
                    .opacity(0.45)
                    .animation(.easeInOut(duration: 0.15), value: phase)
            case .streaming:
                // Tokens arriving live: render the partial rewrite as static
                // text growing in place. No animation — the text appearing
                // IS the animation.
                streamingText
                    .transition(.opacity)
            case .result:
                // Stream complete: the rewrite is editable for tweaks before
                // paste. Hash-stable view identity ensures the editor doesn't
                // remount and lose focus on each output mutation.
                resultEditor
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .animation(.easeInOut(duration: 0.18), value: phase)
    }

    // MARK: - Layers

    /// The plain editable text region — used in `.input` and (dimmed) in
    /// `.working`.
    private var inputLayer: some View {
        SharpieTextView(
            text: $input,
            focusToken: inputFocusToken,
            isEditable: isInputEditable,
            identifier: "sharpieInput"
        )
        .frame(minHeight: 28)
        .overlay(alignment: .topLeading) {
            if input.isEmpty {
                Text(placeholder)
                    .font(textFont)
                    .foregroundStyle(.tertiary)
                    .padding(EdgeInsets(
                        top: SharpieTextView.textInset.height,
                        leading: SharpieTextView.textInset.width,
                        bottom: 0, trailing: 0
                    ))
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    /// Streaming view — the rewrite text rendered as it arrives. Plain
    /// `Text`, selectable, no animation; the user perceives the live
    /// generation as the fastest possible "morph."
    private var streamingText: some View {
        Text(output)
            .font(textFont)
            .lineSpacing(2)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .textSelection(.enabled)
            .padding(.vertical, 2)
    }

    /// Post-stream: the rewrite is editable for tweaks. The output binding
    /// updates the clipboard on edit via the view model's hook.
    private var resultEditor: some View {
        SharpieTextView(
            text: $output,
            focusToken: 0,
            isEditable: true,
            identifier: "sharpieOutput"
        )
        .frame(minHeight: estimatedTextHeight(output))
    }

    // MARK: - Layout helpers

    private var textFont: Font { .system(size: 16) }

    /// Cheap height estimate for the morph layer's GeometryReader frame.
    /// Same heuristic as elsewhere in the app — ~70 chars per visual line at
    /// 22pt per line.
    private func estimatedTextHeight(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return 28 }
        let charsPerLine: Double = 70
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var count = 0
        for line in lines {
            count += max(1, Int(ceil(Double(line.count) / charsPerLine)))
        }
        return CGFloat(max(1, count)) * 22 + 8
    }
}
