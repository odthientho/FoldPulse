import XCTest
import FoldPulseCore
@testable import FoldPulse

@MainActor
final class HingeTrackerTests: XCTestCase {
    func testEdgesAreDeliveredInOrderWithFirstEnteredTimes() async {
        var clock = Date(timeIntervalSince1970: 1_794_200_000)
        let tracker = HingeTracker(now: { clock })
        var received: [HingeEdge] = []
        tracker.onEdge = { received.append($0) }

        tracker.observe(.open, label: "Fully open")      // baseline
        clock += 1; tracker.tick()
        tracker.observe(.closed, label: "Closed")
        let closedAt = clock
        clock += 0.3; tracker.tick()                     // fold committed
        tracker.observe(.open, label: "Partially open")
        let openedAt = clock
        clock += 0.3; tracker.tick()                     // unfold committed
        await tracker.waitForDelivery()

        XCTAssertEqual(received, [HingeEdge(type: .fold, at: closedAt), HingeEdge(type: .unfold, at: openedAt)])
        XCTAssertEqual(tracker.liveLabel, "Partially open")
    }

    func testFlushCommitsAPendingFoldWhenTheAppGoesAway() async {
        var clock = Date(timeIntervalSince1970: 1_794_200_000)
        let tracker = HingeTracker(now: { clock })
        var received: [HingeEdge] = []
        tracker.onEdge = { received.append($0) }
        tracker.observe(.open, label: "Fully open"); clock += 1; tracker.tick()
        tracker.observe(.closed, label: "Closed")
        tracker.flush()
        await tracker.waitForDelivery()
        XCTAssertEqual(received.map(\.type), [.fold])
    }

    func testHingeSeenCallbackFiresOnlyForRealReadings() {
        let tracker = HingeTracker()
        var seen = 0
        tracker.onHingeSeen = { seen += 1 }
        tracker.observe(nil, label: "No hinge reading")
        XCTAssertEqual(seen, 0)
        tracker.observe(.open, label: "Fully open")
        XCTAssertEqual(seen, 1)
    }
}
