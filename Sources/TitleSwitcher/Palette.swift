import AppKit
import Carbon.HIToolbox
import SwitcherCore

private final class PalettePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class Palette: NSObject, NSTextFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private static let width: CGFloat = 640
    private static let rowHeight: CGFloat = 30
    private static let maxVisibleRows = 12
    private static let fieldHeight: CGFloat = 44

    private let panel = PalettePanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
    private let field = NSTextField()
    private let table = NSTableView()
    private var allWindows = [SwitchableWindow]()
    private var rows = [SwitchableWindow]()
    private var keyMonitor: Any?
    private var optionRelease = OptionRelease()

    override init() {
        super.init()
        setUpPanel()
    }

    var isVisible: Bool { panel.isVisible }

    func show(startAtLastRow: Bool = false) {
        allWindows = WindowSource.current()
        field.stringValue = ""
        optionRelease = OptionRelease()
        refilter()
        if startAtLastRow, !rows.isEmpty { select(rows.count - 1) }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] in self?.handle($0) }
    }

    func hide() {
        guard panel.isVisible else { return }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panel.orderOut(nil)
    }

    func moveSelection(by delta: Int) {
        guard !rows.isEmpty else { return }
        let next = (table.selectedRow + delta + rows.count) % rows.count
        select(next)
        optionRelease.selectionMoved(optionHeld: NSEvent.modifierFlags.contains(.option))
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.type == .flagsChanged {
            if !flags.contains(.option), optionRelease.shouldFocusOnRelease { focusSelection() }
            return event
        }
        guard !flags.contains(.command), !flags.contains(.control) else { return event }
        if let row = DigitKey.rowIndex(forKeyCode: event.keyCode) {
            if row < rows.count { focus(rows[row]) }
            return nil
        }
        switch Int(event.keyCode) {
        case kVK_Escape: hide()
        case kVK_Return, kVK_ANSI_KeypadEnter: focusSelection()
        case kVK_DownArrow: moveSelection(by: 1)
        case kVK_UpArrow: moveSelection(by: -1)
        case kVK_Tab: moveSelection(by: flags.contains(.shift) ? -1 : 1)
        default: return typeIgnoringOption(event, flags)
        }
        return nil
    }

    /// While ⌥ is still held from the summon chord, letters would type "å∫ç"; type the plain letter instead.
    private func typeIgnoringOption(_ event: NSEvent, _ flags: NSEvent.ModifierFlags) -> NSEvent? {
        guard flags.contains(.option), let characters = event.charactersIgnoringModifiers, let editor = field.currentEditor() else { return event }
        editor.insertText(characters)
        return nil
    }

    private func refilter() {
        let query = field.stringValue.trimmingCharacters(in: .whitespaces)
        let byId = Dictionary(allWindows.map { ($0.info.id, $0) }, uniquingKeysWith: { first, _ in first })
        rows = WindowFilter.apply(allWindows.map(\.info), query: query).compactMap { byId[$0.id] }
        table.reloadData()
        resize()
        if let index = InitialSelection.index(rowCount: rows.count, query: query) { select(index) }
    }

    private func select(_ row: Int) {
        table.selectRowIndexes([row], byExtendingSelection: false)
        table.scrollRowToVisible(row)
    }

    private func focusSelection() {
        guard rows.indices.contains(table.selectedRow) else { return }
        focus(rows[table.selectedRow])
    }

    private func focus(_ window: SwitchableWindow) {
        hide()
        WindowFocuser.focus(window)
    }

    @objc private func rowClicked() {
        focusSelection()
    }

    func controlTextDidChange(_ notification: Notification) {
        optionRelease.typed()
        refilter()
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: RowView.identifier, owner: nil) as? RowView ?? RowView()
        cell.configure(rows[row], number: row < 9 ? row + 1 : nil)
        return cell
    }

    private func resize() {
        let visibleRows = CGFloat(min(max(rows.count, 1), Palette.maxVisibleRows))
        let height = Palette.fieldHeight + visibleRows * Palette.rowHeight + 8
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let top = visible.maxY - visible.height * 0.2
        panel.setFrame(NSRect(x: visible.midX - Palette.width / 2, y: top - height, width: Palette.width, height: height), display: true)
    }

    private func setUpPanel() {
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self
        panel.contentView = makeContent()
    }

    private func makeContent() -> NSView {
        let background = NSVisualEffectView()
        background.material = .popover
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 12
        background.layer?.masksToBounds = true
        setUpField()
        let scroll = makeTableScroll()
        [field, scroll].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; background.addSubview($0) }
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: background.topAnchor, constant: 10),
            field.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 14),
            field.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -14),
            scroll.topAnchor.constraint(equalTo: background.topAnchor, constant: Palette.fieldHeight),
            scroll.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -4),
            scroll.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -4),
        ])
        return background
    }

    private func setUpField() {
        field.placeholderString = "Search windows   (1–9 to jump)"
        field.font = .systemFont(ofSize: 18)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = self
    }

    private func makeTableScroll() -> NSScrollView {
        table.addTableColumn(NSTableColumn(identifier: .init("window")))
        table.headerView = nil
        table.rowHeight = Palette.rowHeight
        table.backgroundColor = .clear
        table.style = .plain
        table.intercellSpacing = .zero
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(rowClicked)
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        return scroll
    }
}

private final class RowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("row")

    private let number = NSTextField(labelWithString: "")
    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let app = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = RowView.identifier
        number.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        number.textColor = .tertiaryLabelColor
        number.alignment = .right
        title.font = .systemFont(ofSize: 14)
        title.lineBreakMode = .byTruncatingTail
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        app.font = .systemFont(ofSize: 12)
        app.textColor = .secondaryLabelColor
        app.setContentHuggingPriority(.required, for: .horizontal)
        let stack = NSStackView(views: [number, icon, title, app])
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            number.widthAnchor.constraint(equalToConstant: 14),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(_ window: SwitchableWindow, number digit: Int?) {
        number.stringValue = digit.map(String.init) ?? ""
        icon.image = window.app.icon
        title.stringValue = window.info.title
        title.textColor = window.isMinimized ? .secondaryLabelColor : .labelColor
        app.stringValue = window.info.appName
    }
}
