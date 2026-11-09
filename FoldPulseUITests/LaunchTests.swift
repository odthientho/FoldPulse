import XCTest

/// Smoke test: the app launches into Today with all four tabs reachable.
final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchShowsTodayAndTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Ready when you are"].exists, "empty state on a fresh store")

        for tab in ["History", "Insights", "Settings"] {
            let button = app.buttons[tab].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5), "missing tab \(tab)")
            button.tap()
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 5))
        }
    }

    /// F4 end to end: manual recording updates Today and History; Undo is offered.
    @MainActor
    func testRecordingAFoldManuallyUpdatesTodayAndHistory() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let record = app.buttons["Record"].firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10))
        record.tap()
        let recordFold = app.buttons["Record Fold"]
        XCTAssertTrue(recordFold.waitForExistence(timeout: 5))
        recordFold.tap()
        XCTAssertTrue(app.staticTexts["Fold recorded · Manual"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Undo"].exists)
        app.buttons["Close"].firstMatch.tap()

        let hero = app.descendants(matching: .any)["heroCounter"]
        XCTAssertTrue(hero.waitForExistence(timeout: 5))
        XCTAssertEqual(hero.label, "1 fold since install")

        app.buttons["History"].firstMatch.tap()
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Fold'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "the recorded fold appears in History")
    }
}
