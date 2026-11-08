import AppKit
import Carbon.HIToolbox
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private let palette = Palette()
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
        hotKey = HotKey(keyCode: kVK_Tab, modifiers: optionKey) { [weak self] in self?.summon() }
        statusItem = makeStatusItem()
    }

    private func summon() {
        palette.isVisible ? palette.moveSelection(by: 1) : palette.show()
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "TitleSwitcher")
        let menu = NSMenu()
        menu.addItem(withTitle: "Show (⌥⇥)", action: #selector(showFromMenu), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit TitleSwitcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        return item
    }

    @objc private func showFromMenu() {
        palette.show()
    }

    @objc private func toggleOpenAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            }
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleOpenAtLogin) {
            menuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
