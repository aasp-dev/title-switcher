import Carbon.HIToolbox

/// Carbon hotkeys need no Input Monitoring permission and swallow the chord system-wide.
final class HotKey {
    private static var handlers = [UInt32: () -> Void]()
    private static let installDispatcher: Void = {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            HotKey.handlers[id.id]?()
            return noErr
        }, 1, &spec, nil, nil)
    }()

    private var ref: EventHotKeyRef?

    init(keyCode: Int, modifiers: Int, onPress: @escaping () -> Void) {
        HotKey.installDispatcher
        let id = EventHotKeyID(signature: OSType(0x5453_5754), id: UInt32(HotKey.handlers.count + 1))
        HotKey.handlers[id.id] = onPress
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
        if status != noErr { NSLog("TitleSwitcher: hotkey registration failed (\(status)); is another app using this shortcut?") }
    }
}
