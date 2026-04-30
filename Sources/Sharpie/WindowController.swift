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
    // the input, expands when streaming, copied, clarifying, or showing an
    // error. Anchored at the top so the user's eye doesn't have to chase it.
    private static let compactHeight: CGFloat = 110
    private static let expandedHeight: CGFloat = 360
    private static let windowWidth: CGFloat = 600

    private let viewModel: SharpenViewModel
    private var window: FocusableWindow?
    private var settingsWindow: NSWindow?
    private var localKeyMonitor: Any?
    private var statusObserver: AnyCancellable?

    init(systemPrompt: String) {
        self.viewModel = SharpenViewModel(systemPrompt: systemPrompt)
        statusObserver = viewModel.$status
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self, let window = self.window else { return }
                self.adjustSize(for: status, animated: window.isVisible)
            }
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
        adjustSize(for: viewModel.status, animated: false)
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
            onDismiss: { [weak self] in self?.hide() }
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

    /// Resizes the window to match the viewmodel state. Anchored to the
    /// window's current top edge so the input doesn't jump under the cursor
    /// when the output area expands.
    private func adjustSize(for status: SharpenViewModel.Status, animated: Bool) {
        guard let window else { return }
        let target = needsExpansion(status) ? Self.expandedHeight : Self.compactHeight
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

    private func needsExpansion(_ status: SharpenViewModel.Status) -> Bool {
        switch status {
        case .idle: return false
        case .streaming, .copied, .clarifying, .error: return true
        }
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

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        // Esc → dismiss.
        if event.keyCode == 53 {
            hide()
            return nil
        }
        // ⌘Z → revert to original input, but only when there's a rewrite or
        // clarify question on screen. While the user is still typing the
        // original (idle), let ⌘Z fall through so the text view's normal
        // undo works for typing mistakes.
        if event.keyCode == 6 && event.modifierFlags.contains(.command) {
            switch viewModel.status {
            case .copied, .clarifying:
                viewModel.revertToOriginal()
                return nil
            case .idle, .streaming, .error:
                return event
            }
        }
        // Return (no Shift) → submit, or dismiss when the rewrite is already
        // copied. Shift+Return falls through so TextEditor inserts a newline.
        if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
            switch viewModel.status {
            case .streaming:
                return nil
            case .copied:
                hide()
                return nil
            case .idle, .clarifying, .error:
                viewModel.submit()
                return nil
            }
        }
        return event
    }

    // MARK: - Settings window

    func showSettings() {
        if settingsWindow == nil {
            let w = NSWindow(
                contentRect: NSRect(origin: .zero, size: NSSize(width: 460, height: 220)),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            w.title = "Sharpie Settings"
            w.isReleasedWhenClosed = false
            let view = SettingsView(onClose: { [weak self] in
                self?.settingsWindow?.close()
            })
            w.contentView = NSHostingView(rootView: view)
            w.center()
            settingsWindow = w
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
