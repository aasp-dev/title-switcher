import AppKit
import SwitcherCore

/// Private but stable since 10.x; the only way to map an AX window to its CGWindowID for z-ordering.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ id: inout CGWindowID) -> AXError

struct SwitchableWindow {
    let info: WindowInfo
    let element: AXUIElement
    let app: NSRunningApplication
    let isMinimized: Bool
}

/// Titles come from Accessibility, so no Screen Recording permission is needed.
/// AX only lists windows of the current Space (plus minimized ones).
enum WindowSource {
    private static let perAppTimeout: Float = 0.15

    static func current() -> [SwitchableWindow] {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular && $0.processIdentifier != getpid() }
        let windows = collectConcurrently(apps)
        let ordered = WindowOrdering.byZOrder(windows.map(\.info), frontToBack: frontToBackWindowIds())
        let byId = Dictionary(windows.map { ($0.info.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ordered.compactMap { byId[$0.id] }
    }

    private static func collectConcurrently(_ apps: [NSRunningApplication]) -> [SwitchableWindow] {
        var perApp = [[SwitchableWindow]](repeating: [], count: apps.count)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: apps.count) { index in
            let windows = windowsOf(apps[index])
            lock.withLock { perApp[index] = windows }
        }
        return perApp.flatMap { $0 }
    }

    private static func windowsOf(_ app: NSRunningApplication) -> [SwitchableWindow] {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(axApp, perAppTimeout)
        let elements: [AXUIElement] = attribute(axApp, kAXWindowsAttribute) ?? []
        let appName = app.localizedName ?? ""
        return elements.compactMap { element in
            guard attribute(element, kAXSubroleAttribute) == kAXStandardWindowSubrole as String else { return nil }
            var id: CGWindowID = 0
            guard _AXUIElementGetWindow(element, &id) == .success, id != 0 else { return nil }
            let title: String = attribute(element, kAXTitleAttribute) ?? ""
            let info = WindowInfo(id: id, title: title.isEmpty ? appName : title, appName: appName)
            return SwitchableWindow(info: info, element: element, app: app, isMinimized: attribute(element, kAXMinimizedAttribute) ?? false)
        }
    }

    private static func frontToBackWindowIds() -> [UInt32] {
        let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return list.filter { ($0[kCGWindowLayer as String] as? Int) == 0 }.compactMap { $0[kCGWindowNumber as String] as? UInt32 }
    }

    static func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}

enum WindowFocuser {
    static func focus(_ window: SwitchableWindow) {
        if window.app.isHidden { window.app.unhide() }
        if window.isMinimized { AXUIElementSetAttributeValue(window.element, kAXMinimizedAttribute as CFString, kCFBooleanFalse) }
        NSApp.yieldActivation(to: window.app)
        window.app.activate()
        AXUIElementSetAttributeValue(window.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(window.element, kAXRaiseAction as CFString)
    }
}
