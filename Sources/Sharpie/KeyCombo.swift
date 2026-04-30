import AppKit
import Carbon.HIToolbox
import Foundation

// Hotkey combination. Stored in UserDefaults so it survives relaunches.
// We persist the Carbon-style key code + modifier mask plus a human-
// readable display character — `displayChar` lets us render "⌘⇧K" without
// having to maintain a giant kVK_* → string table at draw time.
struct KeyCombo: Equatable, Codable, Sendable {
    let carbonKeyCode: UInt32
    let carbonModifiers: UInt32
    let displayChar: String

    static let `default` = KeyCombo(
        carbonKeyCode: UInt32(kVK_ANSI_Slash),
        carbonModifiers: UInt32(cmdKey),
        displayChar: "/"
    )

    var display: String {
        var out = ""
        if carbonModifiers & UInt32(controlKey) != 0 { out += "⌃" }
        if carbonModifiers & UInt32(optionKey)  != 0 { out += "⌥" }
        if carbonModifiers & UInt32(shiftKey)   != 0 { out += "⇧" }
        if carbonModifiers & UInt32(cmdKey)     != 0 { out += "⌘" }
        out += displayChar
        return out
    }

    /// Build from a recorder NSEvent. Returns nil if no modifiers are
    /// pressed — bare keys are too prone to collide with normal typing.
    init?(from event: NSEvent) {
        let nsMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbonMods: UInt32 = 0
        if nsMods.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if nsMods.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if nsMods.contains(.control) { carbonMods |= UInt32(controlKey) }
        if nsMods.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        guard carbonMods != 0 else { return nil }

        let keyCode = UInt32(event.keyCode)
        let display = KeyCombo.displayString(forKeyCode: keyCode, event: event)

        self.carbonKeyCode = keyCode
        self.carbonModifiers = carbonMods
        self.displayChar = display
    }

    init(carbonKeyCode: UInt32, carbonModifiers: UInt32, displayChar: String) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = carbonModifiers
        self.displayChar = displayChar
    }

    private static func displayString(forKeyCode keyCode: UInt32, event: NSEvent) -> String {
        // Special keys we always want to render with a friendly name.
        switch Int(keyCode) {
        case kVK_Space:        return "Space"
        case kVK_Return:       return "↩"
        case kVK_Tab:          return "⇥"
        case kVK_Delete:       return "⌫"
        case kVK_ForwardDelete:return "⌦"
        case kVK_Escape:       return "⎋"
        case kVK_LeftArrow:    return "←"
        case kVK_RightArrow:   return "→"
        case kVK_UpArrow:      return "↑"
        case kVK_DownArrow:    return "↓"
        case kVK_F1:  return "F1"
        case kVK_F2:  return "F2"
        case kVK_F3:  return "F3"
        case kVK_F4:  return "F4"
        case kVK_F5:  return "F5"
        case kVK_F6:  return "F6"
        case kVK_F7:  return "F7"
        case kVK_F8:  return "F8"
        case kVK_F9:  return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: break
        }
        // For printable keys, NSEvent gives us the unmodified character.
        // Uppercase looks more like the standard menu shortcut rendering.
        if let chars = event.charactersIgnoringModifiers, let first = chars.first {
            return String(first).uppercased()
        }
        return "Key \(keyCode)"
    }
}
