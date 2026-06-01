import Cocoa
import Carbon.HIToolbox

class HotkeyManager {
    private let onTrigger: () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    func register() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4D545F54) // "MT_T"
        hotKeyID.id = 1

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            NSLog("[MacTranslator] hotkey event received")
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let mgr = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { mgr.onTrigger() }
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPtr, &eventHandler)

        // ⌥T (Option + T), T = kVK_ANSI_T = 0x11
        RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(optionKey), hotKeyID,
                            GetApplicationEventTarget(), 0, &hotkeyRef)
    }

    deinit {
        if let ref = hotkeyRef { UnregisterEventHotKey(ref) }
        if let handler = eventHandler { RemoveEventHandler(handler) }
    }
}