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
    /// When false, the text view stays visible but doesn't accept edits.
    /// We use this to lock the input while a rewrite is streaming so the
    /// user can read what they sent without accidentally typing into it.
    var isEditable: Bool = true
    /// Identifier propagated to the underlying NSTextView so the
    /// WindowController's local key monitor can tell which field has focus
    /// (input vs output editor) when deciding what ⌘Z should do.
    var identifier: String? = nil
    /// Fired when editing ends (focus leaves, window resigns key, etc.).
    /// PR B will use this to capture history revisions.
    var onCommit: ((String) -> Void)? = nil

    /// Inset between the scroll view bounds and where the first character
    /// renders. The placeholder overlay must use these same values for the
    /// caret and placeholder to share a baseline.
    static let textInset = NSSize(width: 5, height: 8)

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        // Modern macOS overlay scrollers fade in only when the user
        // actively scrolls. autohidesScrollers means they disappear when
        // there's nothing to scroll. The result: zero visual noise on a
        // short input, an unobtrusive bar that lets a long input still
        // be reached.
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.borderType = .noBorder
        scroll.verticalScrollElasticity = .allowed

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.drawsBackground = false
        textView.isEditable = isEditable
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
        if let identifier {
            textView.identifier = NSUserInterfaceItemIdentifier(identifier)
        }

        scroll.documentView = textView
        context.coordinator.textView = textView
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
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

        func textDidEndEditing(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.onCommit?(tv.string)
        }
    }
}
