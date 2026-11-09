import XCTest

/// PF-04: cold launch time (simulator, indicative).
final class LaunchPerformanceTests: XCTestCase {
    @MainActor
    func testColdLaunchTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-ui-testing"]
            app.launch()
        }
    }
}
