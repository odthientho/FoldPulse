import XCTest

/// Captures screenshots of the running MVP (sample data) for the Phase 4 report.
/// CI exports them from the result bundle as the "screenshots" artifact.
final class ScreenshotTests: XCTestCase {
    @MainActor
    func testCaptureMainScreensWithSampleData() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        tab(app, "Settings")
        let insert = app.buttons["Insert sample week"]
        XCTAssertTrue(insert.waitForExistence(timeout: 10))
        insert.tap()
        snap(app, "05-settings")

        tab(app, "Today")
        XCTAssertTrue(app.descendants(matching: .any)["heroCounter"].waitForExistence(timeout: 10))
        sleep(1)
        snap(app, "01-today")

        app.buttons["Record"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Record Fold"].waitForExistence(timeout: 5))
        app.buttons["Record Fold"].tap()
        XCTAssertTrue(app.staticTexts["Fold recorded · Manual"].waitForExistence(timeout: 5))
        snap(app, "02-record-sheet")
        app.buttons["Close"].firstMatch.tap()

        tab(app, "History")
        sleep(1)
        snap(app, "03-history")

        tab(app, "Insights")
        sleep(2)
        snap(app, "04-insights")
    }

    @MainActor
    private func tab(_ app: XCUIApplication, _ name: String) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "missing tab \(name)")
        button.tap()
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
