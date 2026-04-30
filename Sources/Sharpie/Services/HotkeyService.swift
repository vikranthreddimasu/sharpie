import AppKit
import Carbon.HIToolbox

// We use Carbon's RegisterEventHotKey instead of NSEvent.addGlobalMonitorForEvents
// because the latter requires Accessibility permission and only *observes* events
// — it can't suppress them, so the hotkey would also reach whatever app the user
// is focused on. RegisterEventHotKey installs a real system-wide hotkey that
// fires regardless of focus and consumes the event. The price is the C trampoline
// below. Worth it for the UX.

final class HotkeyService {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var onFire: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32, _ handler: @escaping () -> Void) {
        unregister()
        onFire = handler

        let signature: OSType = 0x53415250 // 'SARP'
        let hotkeyID = EventHotKeyID(signature: signature, id: 1)

        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        guard registerStatus == noErr else { return }
        hotKeyRef = ref

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let trampoline: EventHandlerUPP = { _, _, userData in
            guard let userData else { return noErr }
            let svc = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { svc.onFire?() }
            return noErr
        }

        var ehRef: EventHandlerRef?
        InstallEventHandler(
            GetEventDispatcherTarget(),
            trampoline,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &ehRef
        )
        handlerRef = ehRef
    }

    func unregister() {
        if let h = handlerRef {
            RemoveEventHandler(h)
            handlerRef = nil
        }
        if let h = hotKeyRef {
            UnregisterEventHotKey(h)
            hotKeyRef = nil
        }
    }

    deinit {
        unregister()
    }
}

// Convenience constants. Keys are the Carbon virtual key codes.
enum DefaultHotkey {
    static let keyCode: UInt32 = UInt32(kVK_ANSI_Slash)
    static let modifiers: UInt32 = UInt32(cmdKey)
}
