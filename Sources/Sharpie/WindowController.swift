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

    // Single morph surface: window height tracks one content area + a thin
    // hairline + padding. No "input zone vs output zone" math — just one
    // text region that morphs through states.
    private static let compactHeight: CGFloat = 84       // one-line input + hairline
    private static let setupHeight: CGFloat = 320        // first-run install rows
    private static let maxHeight: CGFloat = 580
    private static let windowWidth: CGFloat = 600

    let viewModel: SharpenViewModel
    let historyStore: HistoryStore
    let detector: BackendDetector
    private var window: FocusableWindow?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var localKeyMonitor: Any?
    private var observers: Set<AnyCancellable> = []

    // Mac virtual keycodes — Foundation/AppKit don't expose constants for
    // these, and `NSEvent.charactersIgnoringModifiers` is locale-sensitive
    // for things like comma on AZERTY. Using keyCodes keeps the bindings
    // physical-position-stable across keyboard layouts.
    private enum KeyCode {
        static let escape: UInt16 = 53
        static let returnKey: UInt16 = 36
        static let z: UInt16 = 6
        static let y: UInt16 = 16
        static let comma: UInt16 = 43
    }

    init(systemPrompt: String, historyStore: HistoryStore, detector: BackendDetector) {
        self.historyStore = historyStore
        self.detector = detector
        self.viewModel = SharpenViewModel(
            systemPrompt: systemPrompt,
            historyStore: historyStore,
            detector: detector
        )
        // Adapt the window when status changes, when the rewrite arrives,
        // or when the user types/pastes a longer input. Three publishers,
        // one debounced re-layout per change.
        let trigger = Publishers.CombineLatest3(
            viewModel.$status,
            viewModel.$output,
            viewModel.$input
        )
        .map { _, _, _ in () }
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
            detector: detector,
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

    /// Single-surface height: one content area sized by the longer of the
    /// two texts (input vs. rewrite), plus the hairline and padding. Anchor
    /// at the top so the user's eye doesn't chase the input.
    private func desiredHeight() -> CGFloat {
        // 14 (top pad) + content + 10 (bottom pad of surface) + 12 (hairline area) + 8 (bottom pad)
        let chrome: CGFloat = 14 + 10 + 12 + 8

        switch viewModel.status {
        case .needsSetup:
            return Self.setupHeight

        case .idle, .working, .error:
            let h = visualHeight(for: viewModel.input, perLine: 22)
            let content: CGFloat = max(28, min(360, h + 6))
            var total = content + chrome
            if case .error = viewModel.status { total += 22 }  // error message line
            return min(Self.maxHeight, max(Self.compactHeight, total))

        case .streaming, .copied:
            // The input is gone — show the rewrite. As tokens stream in,
            // viewModel.output grows; this re-fires per chunk and grows
            // the window in lockstep so the latest text is always visible.
            let outH = visualHeight(for: viewModel.output, perLine: 22)
            let content: CGFloat = max(28, min(440, outH + 6))
            return min(Self.maxHeight, max(Self.compactHeight, content + chrome))
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

    /// True when the editable output text view is the window's first
    /// responder. The morph surface mounts a SharpieTextView with
    /// identifier "sharpieOutput" once the rewrite has settled — when the
    /// user is editing the rewrite, ⌘Z should mean "undo the last keystroke,"
    /// not "revert to original input."
    private func isOutputEditorFocused() -> Bool {
        guard let responder = window?.firstResponder as? NSTextView else { return false }
        return responder.identifier?.rawValue == "sharpieOutput"
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        // Esc → dismiss.
        if event.keyCode == KeyCode.escape {
            hide()
            return nil
        }
        // ⌘, → open Settings from the prompt window. Previously this only
        // worked through the menu-bar item's keyEquivalent, which required
        // the user to click the menu icon first. Now it's a real shortcut.
        if event.keyCode == KeyCode.comma && event.modifierFlags.contains(.command) {
            hide()
            showSettings()
            return nil
        }
        // ⌘Y → open History. Same fix as ⌘, — it was menu-only.
        if event.keyCode == KeyCode.y && event.modifierFlags.contains(.command) {
            hide()
            showHistory()
            return nil
        }
        // ⌘Z is context-sensitive:
        //   - while the output editor has focus → standard text undo
        //     (NSTextView handles it; we just don't intercept).
        //   - while the input is focused and a rewrite/clarify is on
        //     screen → revert to the original input.
        //   - everywhere else → fall through to the Edit menu's Undo so
        //     the text view's native undo works for typing mistakes.
        if event.keyCode == KeyCode.z && event.modifierFlags.contains(.command) {
            if isOutputEditorFocused() {
                return event
            }
            switch viewModel.status {
            case .copied:
                viewModel.revertToOriginal()
                return nil
            case .idle, .working, .streaming, .error, .needsSetup:
                return event
            }
        }
        // Return (no Shift) → submit, or dismiss when the rewrite is already
        // copied. Shift+Return falls through so TextEditor inserts a newline.
        // While the output editor is focused, *all* Return keys belong to
        // the editor for newlines — don't intercept.
        if event.keyCode == KeyCode.returnKey && !event.modifierFlags.contains(.shift) {
            if isOutputEditorFocused() {
                return event
            }
            switch viewModel.status {
            case .working, .streaming:
                return nil
            case .copied:
                hide()
                return nil
            case .needsSetup:
                // Let the SwiftUI default-action button (Open Settings) handle
                // Return — fall through so the responder chain delivers it.
                return event
            case .idle, .error:
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
        // Rebuild the SwiftUI view on every open so it re-scans for newly
        // installed CLIs and reflects current detector state.
        let fresh = SettingsView(
            detector: detector,
            onClose: { [weak self] in
                self?.settingsWindow?.close()
            }
        )
        settingsWindow?.contentView = NSHostingView(rootView: fresh)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
