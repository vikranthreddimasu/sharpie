import AppKit
import SwiftUI

// SwiftUI's TextEditor wraps an NSScrollView whose scrollers we can't
// reliably hide and whose first-line metrics don't match a SwiftUI Text we
// might overlay as a placeholder. This is a thin NSViewRepresentable that
// gives us exact control over both: no scroller, deterministic insets, and
// font/text metrics we can mirror in the placeholder.
struct SharpieTextView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat = 15
    /// Bumped externally to pull focus into this field.
    var focusToken: Int

    /// Inset between the scroll view bounds and where the first character
    /// renders. The placeholder overlay must use these same values for the
    /// caret and placeholder to share a baseline.
    static let textInset = NSSize(width: 5, height: 8)

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.verticalScrollElasticity = .allowed
        scroll.scrollerStyle = .overlay

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.usesFontPanel = false
        textView.usesFindBar = false
        textView.textContainerInset = Self.textInset
        textView.textContainer?.lineFragmentPadding = 0
        textView.autoresizingMask = [.width]
        textView.string = text

        scroll.documentView = textView
        context.coordinator.textView = textView
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.applyFocus(focusToken)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SharpieTextView
        weak var textView: NSTextView?
        private var lastFocusToken: Int = .min

        init(_ parent: SharpieTextView) {
            self.parent = parent
        }

        func applyFocus(_ token: Int) {
            guard token != lastFocusToken else { return }
            lastFocusToken = token
            // Defer one runloop tick so the view has a window to make
            // first-responder in (during the very first updateNSView the
            // scroll view may still be unparented).
            DispatchQueue.main.async { [weak self] in
                guard let tv = self?.textView else { return }
                tv.window?.makeFirstResponder(tv)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            if parent.text != tv.string {
                parent.text = tv.string
            }
        }
    }
}
