import AppKit
import SwiftUI

// Borderless windows can't become key/main by default. Subclassing fixes that.
final class FocusableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class SharpenWindowController {

    private let viewModel: SharpenViewModel
    private var window: FocusableWindow?
    private var settingsWindow: NSWindow?
    private var localKeyMonitor: Any?

    init(systemPrompt: String) {
        self.viewModel = SharpenViewModel(systemPrompt: systemPrompt)
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
        let initialSize = NSSize(width: 600, height: 360)
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
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visible = screen?.visibleFrame else { return }
        let f = w.frame
        let origin = NSPoint(
            x: visible.midX - f.width / 2,
            y: visible.midY - f.height / 2 + 60 // sit slightly above center
        )
        w.setFrameOrigin(origin)
    }

    // MARK: - Local key handling

    // The clean way to map Esc/⌘Z without burdening every SwiftUI view with
    // .keyboardShortcut. Local monitor only fires while our window is key, so
    // we don't fight the user's shortcuts elsewhere.
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
        // ⌘Z → revert to original input.
        if event.keyCode == 6 && event.modifierFlags.contains(.command) {
            viewModel.revertToOriginal()
            return nil
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
