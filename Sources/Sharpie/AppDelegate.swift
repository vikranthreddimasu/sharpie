import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var hotkey: HotkeyService!
    private var windowController: SharpenWindowController!
    private var historyStore: HistoryStore!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let prompt = (try? SystemPromptLoader.load()) ?? Self.fallbackPrompt
        historyStore = HistoryStore()
        windowController = SharpenWindowController(
            systemPrompt: prompt,
            historyStore: historyStore
        )
        installMainMenu()
        installStatusItem()
        installHotkey()
        firstRunFlowIfNeeded()
    }

    /// If the user has no provider key on file, surface Settings on launch
    /// so they aren't staring at a menu-bar icon with nothing to do. Apple
    /// Intelligence skips this — when it's ready, Sharpie works out of the
    /// box with zero configuration.
    private func firstRunFlowIfNeeded() {
        let hasOpenRouter = (KeychainService.get(.openrouter) != nil)
        let hasAnthropic  = (KeychainService.get(.anthropic) != nil)
        let envHasKey =
            ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.isEmpty == false
            || ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]?.isEmpty == false
        let hasAppleIntelligence = ProviderFactory.isAppleIntelligenceReady
        guard !hasOpenRouter && !hasAnthropic && !envHasKey && !hasAppleIntelligence else { return }

        // Defer to the next runloop tick so the status item is on screen
        // first — otherwise Settings appears with the menu bar still
        // resolving and feels jumpy.
        DispatchQueue.main.async { [weak self] in
            self?.windowController.showSettings()
        }
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

        let historyItem = NSMenuItem(
            title: "History…",
            action: #selector(openHistory),
            keyEquivalent: "y"
        )
        historyItem.target = self
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(
            title: "About Sharpie",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

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
        hotkey.register(combo: AppPreferences.hotkey) { [weak self] in
            self?.toggleWindow()
        }

        // Re-register when the user changes the shortcut in Settings —
        // no app restart needed.
        NotificationCenter.default.addObserver(
            forName: .sharpieHotkeyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.hotkey.register(combo: AppPreferences.hotkey) {
                    self?.toggleWindow()
                }
            }
        }
    }

    @objc private func toggleWindow() {
        windowController.toggle()
    }

    @objc private func openSettings() {
        windowController.showSettings()
    }

    @objc private func openHistory() {
        windowController.showHistory()
    }

    @objc private func openAbout() {
        // .accessory apps don't get the standard about panel "for free"
        // through the app menu; we present it manually with explicit
        // attribution so the panel is consistent regardless of how the
        // build was bundled.
        let credits = NSAttributedString(
            string: "MIT licensed.\nSystem prompt: prompts/sharpen.md\ngithub.com/vikranthreddimasu/sharpie",
            attributes: [.font: NSFont.systemFont(ofSize: 11)]
        )
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.applicationName: "Sharpie",
            NSApplication.AboutPanelOptionKey.applicationVersion: "0.1",
            NSApplication.AboutPanelOptionKey.version: "0.1.0",
            NSApplication.AboutPanelOptionKey.credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"):
                "MIT — Vikranth Reddimasu"
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    private static let fallbackPrompt: String = """
    You are Sharpie. Rewrite the user's lazy prompt as the prompt they should
    have typed for an AI coding tool. Output only the rewritten prompt — no
    preamble — or, when the input is genuinely uninterpretable, ask exactly
    one specific clarifying question ending with "?".
    """
}
