import Carbon.HIToolbox

/// Carbon hotkeys need no Input Monitoring permission and swallow the chord system-wide.
final class HotKey {
    private static var onPress: (() -> Void)?
    private var ref: EventHotKeyRef?

    init(keyCode: Int, modifiers: Int, onPress: @escaping () -> Void) {
        HotKey.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKey.onPress?()
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x5453_5754), id: 1)
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
        if status != noErr { NSLog("TitleSwitcher: hotkey registration failed (\(status)); is another app using ⌥⇥?") }
    }
}
