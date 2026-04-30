import AppKit

// We use @main on a @MainActor struct rather than a top-level `main.swift`
// because Swift 6 forbids calling main-actor initializers from the implicit
// nonisolated context of a script-style file. Same effect, satisfied compiler.
//
// .accessory is set at runtime so this binary behaves as a menu-bar app
// whether it's launched as a loose executable or bundled inside Sharpie.app.
@main
@MainActor
struct SharpieApp {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.run()
    }
}
