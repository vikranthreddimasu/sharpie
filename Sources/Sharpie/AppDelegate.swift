import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var hotkey: HotkeyService!
    private var windowController: SharpenWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let prompt = (try? SystemPromptLoader.load()) ?? Self.fallbackPrompt
        windowController = SharpenWindowController(systemPrompt: prompt)
        installStatusItem()
        installHotkey()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "pencil.tip.crop.circle",
                accessibilityDescription: "Sharpie"
            )
            button.imagePosition = .imageOnly
            button.toolTip = "Sharpie — sharpen a lazy prompt (⌘/)"
        }

        let menu = NSMenu()
        let openItem = NSMenuItem(
            title: "Sharpen…   ⌘/",
            action: #selector(toggleWindow),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(
            title: "Set Anthropic API Key…",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Sharpie",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    private func installHotkey() {
        hotkey = HotkeyService()
        hotkey.register(
            keyCode: DefaultHotkey.keyCode,
            modifiers: DefaultHotkey.modifiers
        ) { [weak self] in
            self?.toggleWindow()
        }
    }

    @objc private func toggleWindow() {
        windowController.toggle()
    }

    @objc private func openSettings() {
        windowController.showSettings()
    }

    private static let fallbackPrompt: String = """
    You are Sharpie. Rewrite the user's lazy prompt as the prompt they should
    have typed for an AI coding tool. Output only the rewritten prompt — no
    preamble — or, when the input is genuinely uninterpretable, ask exactly
    one specific clarifying question ending with "?".
    """
}
