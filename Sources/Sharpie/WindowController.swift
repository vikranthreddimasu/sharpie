import AppKit
import Combine
import SwiftUI

// Borderless windows can't become key/main by default. Subclassing fixes that.
final class FocusableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class SharpenWindowController {

    // The window collapses to compact when there's nothing to render below
    // the input, expands proportionally to output length up to a max so
    // long rewrites have room without taking over the screen. Anchored at
    // the top so the user's eye doesn't have to chase it.
    private static let compactHeight: CGFloat = 110
    private static let baseExpandedHeight: CGFloat = 280
    private static let maxExpandedHeight: CGFloat = 620
    private static let windowWidth: CGFloat = 600

    let viewModel: SharpenViewModel
    let historyStore: HistoryStore
    private var window: FocusableWindow?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var localKeyMonitor: Any?
    private var observers: Set<AnyCancellable> = []

    init(systemPrompt: String, historyStore: HistoryStore) {
        self.historyStore = historyStore
        self.viewModel = SharpenViewModel(
            systemPrompt: systemPrompt,
            historyStore: historyStore
        )
        // Adapt the window when state changes, when output grows
        // (streaming chunks, edits), OR when the user types/pastes
        // a longer input. CombineLatest4 fires whenever any of the
        // four publishers emits a new value.
        let trigger = Publishers.CombineLatest4(
            viewModel.$status,
            viewModel.$output,
            viewModel.$outputEditing,
            viewModel.$input
        )
        .map { _, _, _, _ in () }
        .receive(on: DispatchQueue.main)
        trigger
            .sink { [weak self] in
                guard let self, let window = self.window else { return }
                self.adjustSize(animated: window.isVisible)
            }
            .store(in: &observers)
    }

    // MARK: - Main window

    func toggle() {
        if let window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if window == nil { buildMainWindow() }
        guard let window else { return }
        adjustSize(animated: false)
        center(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        viewModel.windowDidOpen()
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        window?.orderOut(nil)
        viewModel.windowDidClose()
    }

    private func buildMainWindow() {
        let initialSize = NSSize(width: Self.windowWidth, height: Self.compactHeight)
        let w = FocusableWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.level = .floating
        w.isMovableByWindowBackground = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        w.titlebarAppearsTransparent = true
        w.animationBehavior = .utilityWindow

        let root = SharpenView(
            viewModel: viewModel,
            onDismiss: { [weak self] in self?.hide() },
            onOpenSettings: { [weak self] in
                self?.hide()
                self?.showSettings()
            }
        )
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: initialSize)
        host.autoresizingMask = [.width, .height]
        w.contentView = host

        window = w
    }

    private func center(_ w: NSWindow) {
        // Center horizontally, sit slightly above vertical center — closer
        // to where the user's eye lives when they invoke the hotkey.
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visible = screen?.visibleFrame else { return }
        let f = w.frame
        let origin = NSPoint(
            x: visible.midX - f.width / 2,
            y: visible.midY - f.height / 2 + 100
        )
        w.setFrameOrigin(origin)
    }

    /// Resizes the window to match the current state. Anchored to the
    /// window's top edge so the input doesn't jump under the cursor when
    /// the output area grows.
    private func adjustSize(animated: Bool) {
        guard let window else { return }
        let target = desiredHeight()
        let current = window.frame
        guard abs(current.height - target) > 0.5 else { return }
        let topY = current.origin.y + current.height
        let newOrigin = NSPoint(x: current.origin.x, y: topY - target)
        let newFrame = NSRect(
            origin: newOrigin,
            size: NSSize(width: Self.windowWidth, height: target)
        )
        window.setFrame(newFrame, display: true, animate: animated)
    }

    /// Heuristic — picks a window height by state, factoring in both
    /// the input the user is typing (so a long paste shows in full) and
    /// the output the model is generating. Capped so a runaway in either
    /// direction can't take over the screen.
    private func desiredHeight() -> CGFloat {
        // Input area height: ~36pt min, scales per visual line, capped
        // around ~320pt + 24pt of padding around it.
        let inputContentHeight = visualHeight(for: viewModel.input, perLine: 22)
        let inputAreaHeight: CGFloat = min(332, max(60, inputContentHeight + 12)) + 24

        // Status bar + dividers below.
        let chromeBelowInput: CGFloat = 40

        switch viewModel.status {
        case .idle:
            // No output area to render — just input + status. Floor at
            // compact (110) so a one-line prompt still feels tight.
            let needed = inputAreaHeight + chromeBelowInput
            return min(Self.maxExpandedHeight, max(Self.compactHeight, needed))
        case .needsSetup, .clarifying, .error:
            return min(Self.maxExpandedHeight, max(Self.baseExpandedHeight, inputAreaHeight + chromeBelowInput + 140))
        case .streaming, .copied:
            let outputContentHeight = visualHeight(for: viewModel.output, perLine: 22)
            // Output area gets at least ~120pt for short rewrites, scales
            // up with content.
            let outputAreaHeight: CGFloat = max(120, outputContentHeight + 32)
            let needed = inputAreaHeight + outputAreaHeight + chromeBelowInput
            return min(Self.maxExpandedHeight, max(Self.baseExpandedHeight, needed))
        }
    }

    /// Visual height for `text` rendered at ~70 chars per soft-wrap and
    /// `perLine` points per line. Same heuristic the SharpenView uses for
    /// the input frame so they grow in lockstep.
    private func visualHeight(for text: String, perLine: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return perLine }
        let charsPerLine: Double = 70
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var count = 0
        for line in lines {
            count += max(1, Int(ceil(Double(line.count) / charsPerLine)))
        }
        return CGFloat(max(1, count)) * perLine
    }

    // MARK: - Local key handling

    // The clean way to map Esc/⌘Z/Return without burdening every SwiftUI view
    // with .keyboardShortcut. Local monitor only fires while our window is
    // key, so we don't fight the user's shortcuts elsewhere.
    private func installKeyMonitor() {
        guard localKeyMonitor == nil else { return }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKey(event)
        }
    }

    private func removeKeyMonitor() {
        if let m = localKeyMonitor {
            NSEvent.removeMonitor(m)
            localKeyMonitor = nil
        }
    }

    /// True when the underlying NSTextView for the output editor is the
    /// window's first responder. We tag the text view with the
    /// "sharpieOutput" identifier in SharpenView so we can recognise it
    /// without keeping a reference around.
    private func isOutputEditorFocused() -> Bool {
        guard let responder = window?.firstResponder as? NSTextView else { return false }
        return responder.identifier?.rawValue == "sharpieOutput"
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        // Esc → dismiss.
        if event.keyCode == 53 {
            hide()
            return nil
        }
        // ⌘Z is context-sensitive:
        //   - while the output editor has focus → standard text undo
        //     (NSTextView handles it; we just don't intercept).
        //   - while the input is focused and a rewrite/clarify is on
        //     screen → revert to the original input (CLAUDE.md spec).
        //   - everywhere else → fall through to the Edit menu's Undo so
        //     the text view's native undo works for typing mistakes.
        if event.keyCode == 6 && event.modifierFlags.contains(.command) {
            if isOutputEditorFocused() {
                return event
            }
            switch viewModel.status {
            case .copied, .clarifying:
                viewModel.revertToOriginal()
                return nil
            case .idle, .streaming, .error, .needsSetup:
                return event
            }
        }
        // Return (no Shift) → submit, or dismiss when the rewrite is already
        // copied. Shift+Return falls through so TextEditor inserts a newline.
        // While the output editor is focused, *all* Return keys belong to
        // the editor for newlines — don't intercept.
        if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
            if isOutputEditorFocused() {
                return event
            }
            switch viewModel.status {
            case .streaming:
                return nil
            case .copied:
                hide()
                return nil
            case .needsSetup:
                // Let the SwiftUI default-action button (Open Settings) handle
                // Return — fall through so the responder chain delivers it.
                return event
            case .idle, .clarifying, .error:
                viewModel.submit()
                return nil
            }
        }
        return event
    }

    // MARK: - Settings window

    func showHistory() {
        if historyWindow == nil {
            let w = NSWindow(
                contentRect: NSRect(origin: .zero, size: NSSize(width: 760, height: 520)),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            w.title = "Sharpie History"
            w.minSize = NSSize(width: 720, height: 460)
            w.isReleasedWhenClosed = false
            historyWindow = w
        }
        let view = HistoryView(
            store: historyStore,
            onClose: { [weak self] in self?.historyWindow?.close() }
        )
        historyWindow?.contentView = NSHostingView(rootView: view)
        historyWindow?.center()
        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings() {
        if settingsWindow == nil {
            let w = NSWindow(
                contentRect: NSRect(origin: .zero, size: NSSize(width: 540, height: 580)),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            w.title = "Sharpie Settings"
            w.isReleasedWhenClosed = false
            settingsWindow = w
        }
        // Rebuild the SwiftUI view on every open so we re-read the
        // Keychain (the "Stored / Replace" indicator must be current) and
        // re-fetch the OpenRouter model list.
        let fresh = SettingsView(onClose: { [weak self] in
            self?.settingsWindow?.close()
        })
        settingsWindow?.contentView = NSHostingView(rootView: fresh)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
