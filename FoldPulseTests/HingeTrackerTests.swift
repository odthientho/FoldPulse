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

        tracker.receive(.fullyOpen)      // baseline
        clock += 1; tracker.tick()
        tracker.receive(.closed)
        let closedAt = clock
        clock += 0.3; tracker.tick()                     // fold committed
        tracker.receive(.partiallyOpen)
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
        tracker.receive(.fullyOpen); clock += 1; tracker.tick()
        tracker.receive(.closed)
        tracker.flush()
        await tracker.waitForDelivery()
        XCTAssertEqual(received.map(\.type), [.fold])
    }

    func testHingeSeenCallbackFiresOnlyForRealReadings() {
        let tracker = HingeTracker()
        var seen = 0
        tracker.onHingeSeen = { seen += 1 }
        tracker.receive(.unavailable)
        XCTAssertEqual(seen, 0)
        tracker.receive(.fullyOpen)
        XCTAssertEqual(seen, 1)
    }

    func testUnknownNeverChangesTheBaseline() async {
        // Review E2: open → unknown → closed must still be a fold.
        var clock = Date(timeIntervalSince1970: 1_794_200_000)
        let tracker = HingeTracker(now: { clock })
        var received: [HingeEdge] = []
        tracker.onEdge = { received.append($0) }
        tracker.receive(.fullyOpen); clock += 1; tracker.tick()
        tracker.receive(.unknown)
        XCTAssertEqual(tracker.liveLabel, "Unknown")
        tracker.receive(.closed); clock += 0.3; tracker.tick()
        await tracker.waitForDelivery()
        XCTAssertEqual(received.map(\.type), [.fold])
    }

    func testReturningToTheAppNeverCreatesAPhantomFold() async {
        // Review E1: app left while open; phone closed meanwhile; app opened on the outer display.
        var clock = Date(timeIntervalSince1970: 1_794_200_000)
        let tracker = HingeTracker(now: { clock })
        var received: [HingeEdge] = []
        tracker.onEdge = { received.append($0) }
        tracker.receive(.fullyOpen); clock += 1; tracker.tick()   // baseline: open
        tracker.resetBaseline()                                   // scene became active again later
        clock += 4 * 3600
        tracker.receive(.closed); clock += 1; tracker.tick()      // first reading: a baseline only
        await tracker.waitForDelivery()
        XCTAssertTrue(received.isEmpty)
    }
}
