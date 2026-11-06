import Foundation

public struct WindowInfo: Equatable {
    public let id: UInt32
    public let title: String
    public let appName: String

    public init(id: UInt32, title: String, appName: String) {
        self.id = id
        self.title = title
        self.appName = appName
    }
}

public enum WindowFilter {
    /// Every whitespace-separated token must appear in the title or app name.
    public static func apply(_ windows: [WindowInfo], query: String) -> [WindowInfo] {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return windows }
        return windows.filter { window in
            let haystack = "\(window.title) \(window.appName)"
            return tokens.allSatisfy { haystack.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }
}

public enum WindowOrdering {
    /// Windows absent from `frontToBack` (minimized, hidden apps) go last, keeping their relative order.
    public static func byZOrder(_ windows: [WindowInfo], frontToBack: [UInt32]) -> [WindowInfo] {
        let rank = Dictionary(frontToBack.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return windows.enumerated()
            .sorted { (rank[$0.element.id] ?? Int.max, $0.offset) < (rank[$1.element.id] ?? Int.max, $1.offset) }
            .map(\.element)
    }
}

public enum InitialSelection {
    /// Row 0 is the window you're on, so with no query we preselect row 1 and Enter toggles back.
    public static func index(rowCount: Int, query: String) -> Int? {
        guard rowCount > 0 else { return nil }
        return query.isEmpty && rowCount > 1 ? 1 : 0
    }
}

public enum DigitKey {
    /// Top-row digit key codes (kVK_ANSI_1...9), which aren't contiguous. Key codes rather than characters,
    /// because ⌥4 types "¢" when the user is still holding ⌥ from the summon shortcut.
    private static let keyCodes: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25]

    public static func rowIndex(forKeyCode keyCode: UInt16) -> Int? {
        keyCodes.firstIndex(of: keyCode)
    }
}
