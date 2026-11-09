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
}
