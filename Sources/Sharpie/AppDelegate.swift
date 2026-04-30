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
        installMainMenu()
        installStatusItem()
        installHotkey()
    }

    /// .accessory apps don't show a menu bar, but they still need a main
    /// menu for ⌘A/⌘C/⌘V/⌘X/⌘Z key equivalents to dispatch through to the
    /// firstResponder (our NSTextView). Without it, those shortcuts don't
    /// work in the input field.
    private func installMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu(title: "Sharpie")
        appMenu.addItem(NSMenuItem(
            title: "Quit Sharpie",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(menuItem(title: "Undo", selector: Selector(("undo:")), key: "z"))
        let redo = menuItem(title: "Redo", selector: Selector(("redo:")), key: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(redo)
        edit.addItem(.separator())
        edit.addItem(menuItem(title: "Cut", selector: #selector(NSText.cut(_:)), key: "x"))
        edit.addItem(menuItem(title: "Copy", selector: #selector(NSText.copy(_:)), key: "c"))
        edit.addItem(menuItem(title: "Paste", selector: #selector(NSText.paste(_:)), key: "v"))
        edit.addItem(.separator())
        edit.addItem(menuItem(title: "Select All", selector: #selector(NSResponder.selectAll(_:)), key: "a"))
        editItem.submenu = edit

        NSApp.mainMenu = main
    }

    private func menuItem(title: String, selector: Selector, key: String) -> NSMenuItem {
        // action=nil + target=nil routes through the responder chain so the
        // firstResponder (NSTextView) handles the standard text editing
        // selectors regardless of which window is key.
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = nil
        return item
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
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
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
