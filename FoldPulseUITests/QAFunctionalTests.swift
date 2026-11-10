import XCTest

/// Phase 5 functional and data UI tests (TEST_PLAN FT-02, FT-03, FT-05, FT-07, DT-01).
final class QAFunctionalTests: XCTestCase {
    @MainActor
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + extra
        app.launch()
        return app
    }

    @MainActor
    private func recordFold(_ app: XCUIApplication) {
        let record = app.buttons["Record"].firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10))
        record.tap()
        let fold = app.buttons["Record Fold"]
        XCTAssertTrue(fold.waitForExistence(timeout: 5))
        fold.tap()
        XCTAssertTrue(app.staticTexts["Fold recorded · Manual"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
    }

    @MainActor
    private func hero(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["heroCounter"]
    }

    /// FT-02 + FT-03 + FT-07: edit an event, filter, then delete it.
    @MainActor
    func testEditFilterAndDeleteAnEvent() throws {
        let app = launch()
        recordFold(app)

        app.buttons["History"].firstMatch.tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Fold'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        app.buttons["Edit"].tap()
        app.buttons["Unfold"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Unfold"].waitForExistence(timeout: 5), "detail shows the new type")
        XCTAssertTrue(app.descendants(matching: .any)["editedRow"].waitForExistence(timeout: 5), "marked edited")

        app.navigationBars.buttons.element(boundBy: 0).tap() // back to History
        app.buttons["Shortcut"].tap()
        XCTAssertTrue(app.staticTexts["No events"].waitForExistence(timeout: 5), "filter hides the manual event")
        app.buttons["All"].tap()

        let edited = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unfold'")).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 5))
        edited.tap()
        app.buttons["Delete event"].tap()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No events"].waitForExistence(timeout: 5))
    }

    /// FT-05: every Insights period renders.
    @MainActor
    func testInsightsPeriodsRender() throws {
        let app = launch()
        recordFold(app)
        app.buttons["Insights"].firstMatch.tap()
        for (period, title) in [("Day", "Today so far"), ("Week", "Last 7 days (incl. today so far)"),
                                ("Month", "This month"), ("Year", "This year")] {
            app.buttons[period].tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "\(period) did not render")
        }
    }

    /// DT-01: data survives the app being terminated and relaunched.
    @MainActor
    func testDataPersistsAcrossRelaunch() throws {
        let first = launch(["-ui-testing-persistent", "-ui-testing-reset"])
        recordFold(first)
        XCTAssertTrue(hero(first).waitForExistence(timeout: 5))
        XCTAssertEqual(hero(first).label, "1 fold since install")
        first.terminate()

        let second = launch(["-ui-testing-persistent"])
        XCTAssertTrue(hero(second).waitForExistence(timeout: 10))
        XCTAssertEqual(hero(second).label, "1 fold since install", "the fold must survive a relaunch")
    }
}
