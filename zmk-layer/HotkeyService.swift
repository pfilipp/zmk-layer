import AppKit
import Carbon.HIToolbox

private let kHotkeySignature: OSType = 0x5A4D4B4C // 'ZMKL'
private let kHotkeyOverlayID: UInt32 = 1

private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData, let event else { return OSStatus(eventNotHandledErr) }
    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()

    var hotkeyID = EventHotKeyID()
    let status = withUnsafeMutableBytes(of: &hotkeyID) { bytes in
        GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            bytes.baseAddress
        )
    }
    guard status == noErr else { return OSStatus(eventNotHandledErr) }

    let hotKeyIDValue = hotkeyID.id
    DispatchQueue.main.async { [service] in
        if hotKeyIDValue == kHotkeyOverlayID {
            service.onHotkeyPressed?()
        }
    }
    return noErr
}

final class HotkeyService {
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var localMonitor: Any?

    func start(settings: HotkeySettings) {
        let combo = settings.overlayShortcut

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
        if handlerStatus != noErr {
            print("[HotkeyService] InstallEventHandler failed: \(handlerStatus)")
        }

        let overlayID = EventHotKeyID(signature: kHotkeySignature, id: kHotkeyOverlayID)
        let registerStatus = withUnsafePointer(to: overlayID) { idPtr in
            RegisterEventHotKey(
                UInt32(combo.keyCode),
                carbonModifiers(from: combo.modifiers),
                idPtr.pointee,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
        }
        if registerStatus != noErr {
            print("[HotkeyService] RegisterEventHotKey failed: \(registerStatus)")
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == combo.keyCode && mods == combo.modifiers {
                self?.onHotkeyPressed?()
                return nil
            }
            return event
        }
    }

    deinit { stop() }

    func stop() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        hotKeyRef = nil
        eventHandlerRef = nil
        localMonitor = nil
    }

    func restart(settings: HotkeySettings) {
        stop()
        start(settings: settings)
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}
