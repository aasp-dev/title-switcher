import Testing
@testable import SwitcherCore

private func window(_ id: UInt32, _ title: String, _ app: String = "App") -> WindowInfo {
    WindowInfo(id: id, title: title, appName: app)
}

@Suite struct WindowFilterTests {
    let windows = [window(1, "README.md — title-switcher", "Zed"), window(2, "Inbox", "Mail"), window(3, "Pull requests · GitHub", "Safari")]

    @Test func emptyQueryKeepsAllWindowsInOrder() {
        #expect(WindowFilter.apply(windows, query: "  ") == windows)
    }

    @Test func matchesTitleCaseAndDiacriticInsensitively() {
        #expect(WindowFilter.apply([window(1, "Café menu")], query: "CAFE").map(\.id) == [1])
    }

    @Test func matchesAppName() {
        #expect(WindowFilter.apply(windows, query: "safari").map(\.id) == [3])
    }

    @Test func everyTokenMustMatchSomewhereInTitleOrAppName() {
        #expect(WindowFilter.apply(windows, query: "zed readme").map(\.id) == [1])
        #expect(WindowFilter.apply(windows, query: "zed inbox").isEmpty)
    }
}

@Suite struct WindowOrderingTests {
    @Test func sortsByFrontToBackZOrder() {
        let windows = [window(1, "a"), window(2, "b"), window(3, "c")]
        #expect(WindowOrdering.byZOrder(windows, frontToBack: [3, 1, 2]).map(\.id) == [3, 1, 2])
    }

    @Test func windowsMissingFromZOrderGoLastKeepingTheirRelativeOrder() {
        let windows = [window(1, "minimized"), window(2, "front"), window(3, "other space")]
        #expect(WindowOrdering.byZOrder(windows, frontToBack: [2]).map(\.id) == [2, 1, 3])
    }
}

@Suite struct InitialSelectionTests {
    @Test func withoutQueryPreselectsThePreviousWindowSoEnterToggles() {
        #expect(InitialSelection.index(rowCount: 5, query: "") == 1)
    }

    @Test func withQueryPreselectsTheBestMatch() {
        #expect(InitialSelection.index(rowCount: 5, query: "mail") == 0)
    }

    @Test func singleRowIsSelected() {
        #expect(InitialSelection.index(rowCount: 1, query: "") == 0)
    }

    @Test func noRowsMeansNoSelection() {
        #expect(InitialSelection.index(rowCount: 0, query: "") == nil)
    }
}

@Suite struct DigitKeyTests {
    @Test func mapsTopRowDigitKeyCodesToZeroBasedRows() {
        #expect([18, 19, 20, 21, 23, 22, 26, 28, 25].map(DigitKey.rowIndex) == Array(0...8))
    }

    @Test func otherKeysAreNotDigits() {
        #expect(DigitKey.rowIndex(forKeyCode: 0) == nil)
        #expect(DigitKey.rowIndex(forKeyCode: 29) == nil)
    }
}
