import XCTest
@testable import FoldPulseCore

final class HingeEdgeDetectorTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_794_200_000)
    private func t(_ s: Double) -> Date { t0.addingTimeInterval(s) }

    func testFirstReadingOnlySetsBaseline() {
        var d = HingeEdgeDetector()
        XCTAssertEqual(d.observe(.open, at: t(0)), [])
        XCTAssertEqual(d.tick(at: t(1)), [], "baseline commits without an edge")
        XCTAssertEqual(d.committed, .open)
    }

    func testFoldAfterDebounceIsTimestampedWhenFirstEntered() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        XCTAssertEqual(d.observe(.closed, at: t(10)), [])
        XCTAssertEqual(d.pendingDeadline, t(10.25))
        XCTAssertEqual(d.tick(at: t(10.1)), [], "not yet stable")
        XCTAssertEqual(d.tick(at: t(10.3)), [HingeEdge(type: .fold, at: t(10))])
        XCTAssertEqual(d.observe(.open, at: t(20)), [])
        XCTAssertEqual(d.tick(at: t(21)), [HingeEdge(type: .unfold, at: t(20))])
    }

    func testBounceAtClosingPointProducesNoEvent() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        _ = d.observe(.closed, at: t(5))
        _ = d.observe(.open, at: t(5.1))   // bounced back within 100 ms
        XCTAssertEqual(d.tick(at: t(6)), [])
        XCTAssertEqual(d.committed, .open)
    }

    func testRepeatedAngleUpdatesKeepTheFirstEnteredTime() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        for step in 0..<20 { _ = d.observe(.closed, at: t(10 + Double(step) * 0.01)) } // many callbacks per fold
        XCTAssertEqual(d.tick(at: t(11)), [HingeEdge(type: .fold, at: t(10))])
    }

    func testNextReadingCommitsAStablePendingStateImmediately() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        _ = d.observe(.closed, at: t(10))
        // No tick arrived (e.g. timer delayed); the next reading commits the stable fold first.
        XCTAssertEqual(d.observe(.open, at: t(12)), [HingeEdge(type: .fold, at: t(10))])
        XCTAssertEqual(d.tick(at: t(13)), [HingeEdge(type: .unfold, at: t(12))])
    }

    func testFlushOnLifecycleChangeKeepsTheFold() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        _ = d.observe(.closed, at: t(10))
        // Closing the phone backgrounds the app before the debounce elapses.
        XCTAssertEqual(d.flush(), [HingeEdge(type: .fold, at: t(10))])
    }

    func testNilResetsBaselineSoResumeDoesNotCreateFalseEvent() {
        var d = HingeEdgeDetector()
        _ = d.observe(.open, at: t(0)); _ = d.tick(at: t(1))
        _ = d.observe(nil, at: t(5))                // left the hierarchy (backgrounded)
        XCTAssertEqual(d.observe(.closed, at: t(100)), [])
        XCTAssertEqual(d.tick(at: t(101)), [], "first reading after nil is a baseline, not a fold")
        XCTAssertEqual(d.committed, .closed)
    }
}
